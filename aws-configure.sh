if ! aws --version | grep -q "aws-cli/2";
then 
    echo "AWS CLI v2 was not found. Please install AWS CLI version 2"
    exit 1
fi

echo "Configuring AWS CLI..."

aws configure set region eu-central-1 --profile openmage.migrationpatches
#aws configure set aws_access_key_id XXX --profile openmage.migrationpatches
#aws configure set aws_secret_access_key XXX --profile openmage.migrationpatches

echo "AWS CLI configured"

exit 0
