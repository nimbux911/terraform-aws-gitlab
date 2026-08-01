#!/bin/bash
set -euo pipefail

exec >> /tmp/backup-replication.log 2>&1
date

exec 9>/var/lock/gitlab-backup-replication.lock
if ! flock -n 9; then
    echo "Another GitLab backup replication is already running"
    exit 0
fi

source_account_id="${source_account_id}"
source_region="${source_region}"
source_vault_name="${source_vault_name}"
source_volume_arn="${source_volume_arn}"
destination_account_id="${destination_account_id}"
destination_region="${destination_region}"
destination_role_arn="${destination_role_arn}"
poll_interval_seconds="${poll_interval_seconds}"
timeout_seconds="${timeout_seconds}"
started_at=$(date +%s)
deadline=$((started_at + timeout_seconds))
destination_copy_started=false
share_added=false
destination_credentials_expires_at=0

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

cleanup() {
    rm -f "$${destination_credentials_file:-}"

    if [ "$share_added" == "true" ] && [ "$destination_copy_started" != "true" ]; then
        aws ec2 modify-snapshot-attribute --snapshot-id "$source_snapshot_id" --attribute createVolumePermission --operation-type remove --user-ids "$destination_account_id" --region "$source_region" || true
    fi
}

trap cleanup EXIT

for command in aws jq flock; do
    command -v "$command" >/dev/null 2>&1 || fail "Required command not found: $command"
done

if [ "$source_region" == "$destination_region" ] && [ "$source_account_id" == "$destination_account_id" ]; then
    fail "The backup replication destination must use another account or region"
fi

assume_destination_role() {
    local credentials

    credentials=$(aws sts assume-role --role-arn "$destination_role_arn" --role-session-name "gitlab-backup-replication" --duration-seconds 43200 --region "$source_region")
    destination_credentials_expires_at=$(date -d "$(echo "$credentials" | jq -r '.Credentials.Expiration')" +%s)
    destination_credentials_file=$(mktemp)
    chmod 600 "$destination_credentials_file"

    cat > "$destination_credentials_file" <<EOF
[destination]
aws_access_key_id=$(echo "$credentials" | jq -r '.Credentials.AccessKeyId')
aws_secret_access_key=$(echo "$credentials" | jq -r '.Credentials.SecretAccessKey')
aws_session_token=$(echo "$credentials" | jq -r '.Credentials.SessionToken')
EOF
}

destination_aws() {
    if [ "$(date +%s)" -ge "$((destination_credentials_expires_at - 300))" ]; then
        rm -f "$destination_credentials_file"
        assume_destination_role
    fi

    AWS_SHARED_CREDENTIALS_FILE="$destination_credentials_file" AWS_PROFILE=destination aws "$@"
}

find_destination_snapshot() {
    destination_aws ec2 describe-snapshots --owner-ids self --region "$destination_region" \
        --filters "Name=tag:ReplicationManaged,Values=true" "Name=tag:ReplicationSourceSnapshotId,Values=$source_snapshot_id" \
        --query 'reverse(sort_by(Snapshots, &StartTime))[0].SnapshotId' --output text
}

wait_for_destination_snapshot() {
    local state

    while [ "$(date +%s)" -lt "$deadline" ]; do
        state=$(destination_aws ec2 describe-snapshots --snapshot-ids "$destination_snapshot_id" --region "$destination_region" --query 'Snapshots[0].State' --output text)

        case "$state" in
            completed)
                return 0
                ;;
            pending)
                sleep "$poll_interval_seconds"
                ;;
            error)
                fail "Destination snapshot $destination_snapshot_id entered error state"
                ;;
            *)
                fail "Destination snapshot $destination_snapshot_id returned unexpected state: $state"
                ;;
        esac
    done

    fail "Timed out waiting for destination snapshot $destination_snapshot_id; source sharing remains enabled while the copy is pending"
}

recovery_point_arn=""
while [ "$(date +%s)" -lt "$deadline" ]; do
    recovery_point=$(aws backup list-recovery-points-by-backup-vault --backup-vault-name "$source_vault_name" --region "$source_region" \
        --query "reverse(sort_by(RecoveryPoints[?ResourceArn=='$source_volume_arn' && Status=='COMPLETED'], &CreationDate))[0].{Arn:RecoveryPointArn,Created:CreationDate}" --output json)
    recovery_point_arn=$(echo "$recovery_point" | jq -r '.Arn // empty')
    recovery_point_created=$(echo "$recovery_point" | jq -r '.Created // empty')

    if [ -n "$recovery_point_arn" ] && [ -n "$recovery_point_created" ]; then
        recovery_point_created_at=$(date -d "$recovery_point_created" +%s)

        if [ "$recovery_point_created_at" -ge "$started_at" ]; then
            break
        fi
    fi

    sleep "$poll_interval_seconds"
done

if [ -z "$recovery_point_arn" ] || [ -z "$${recovery_point_created:-}" ] || [ "$${recovery_point_created_at:-0}" -lt "$started_at" ]; then
    fail "Timed out waiting for a completed GitLab recovery point created after the replication started"
fi

case "$recovery_point_arn" in
    arn:aws:ec2:*::snapshot/snap-*)
        source_snapshot_id="$${recovery_point_arn##*/}"
        ;;
    *)
        fail "Recovery point is not an EBS snapshot ARN: $recovery_point_arn"
        ;;
esac

source_snapshot=$(aws ec2 describe-snapshots --snapshot-ids "$source_snapshot_id" --region "$source_region" --query 'Snapshots[0].{State:State,Encrypted:Encrypted}' --output json)
source_snapshot_state=$(echo "$source_snapshot" | jq -r '.State')
source_snapshot_encrypted=$(echo "$source_snapshot" | jq -r '.Encrypted')

if [ "$source_snapshot_state" != "completed" ]; then
    fail "Source snapshot $source_snapshot_id is not completed: $source_snapshot_state"
fi

if [ "$source_snapshot_encrypted" != "false" ]; then
    fail "Encrypted snapshots are not supported by this backup replication implementation"
fi

assume_destination_role
destination_snapshot_id=$(find_destination_snapshot)

if [ -n "$destination_snapshot_id" ] && [ "$destination_snapshot_id" != "None" ]; then
    destination_copy_started=true
    wait_for_destination_snapshot
    aws ec2 modify-snapshot-attribute --snapshot-id "$source_snapshot_id" --attribute createVolumePermission --operation-type remove --user-ids "$destination_account_id" --region "$source_region" || true
    echo "Snapshot $source_snapshot_id was already replicated as $destination_snapshot_id"
    exit 0
fi

aws ec2 modify-snapshot-attribute --snapshot-id "$source_snapshot_id" --attribute createVolumePermission --operation-type add --user-ids "$destination_account_id" --region "$source_region"
share_added=true

destination_snapshot_id=$(destination_aws ec2 copy-snapshot --source-region "$source_region" --source-snapshot-id "$source_snapshot_id" \
    --description "GitLab backup replicated from $source_snapshot_id" --region "$destination_region" \
    --tag-specifications "ResourceType=snapshot,Tags=[{Key=Name,Value=gitlab-backup-$source_snapshot_id},{Key=Service,Value=gitlab},{Key=ReplicationManaged,Value=true},{Key=ReplicationSourceAccount,Value=$source_account_id},{Key=ReplicationSourceRegion,Value=$source_region},{Key=ReplicationSourceSnapshotId,Value=$source_snapshot_id}]" \
    --query SnapshotId --output text)

if [ -z "$destination_snapshot_id" ] || [ "$destination_snapshot_id" == "None" ]; then
    fail "EC2 did not return a destination SnapshotId"
fi

destination_copy_started=true
wait_for_destination_snapshot

aws ec2 modify-snapshot-attribute --snapshot-id "$source_snapshot_id" --attribute createVolumePermission --operation-type remove --user-ids "$destination_account_id" --region "$source_region"
share_added=false

echo "Replicated $source_snapshot_id to $destination_snapshot_id in account $destination_account_id region $destination_region"
date
