#! /usr/bin/env bash

set -ex

# -- env vars --

# for cloning in delivery
solution_branch=4-troubleshooting

# api
api_service_user=api-user
api_working_dir=/opt/coding-events-api

# needed to use dotnet from within RunCommand
export HOME=/home/student
export DOTNET_CLI_HOME=/home/student

# -- end env vars --

# -- set up API service --

# create API service user and dirs
useradd -M "$api_service_user" -N
mkdir "$api_working_dir"

chmod 700 /opt/coding-events-api/
chown $api_service_user /opt/coding-events-api/

# generate API unit file
cat << EOF > /etc/systemd/system/coding-events-api.service
[Unit]
Description=Coding Events API

[Install]
WantedBy=multi-user.target

[Service]
User=$api_service_user
WorkingDirectory=$api_working_dir
ExecStart=/usr/bin/dotnet ${api_working_dir}/CodingEventsAPI.dll
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=coding-events-api
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false
Environment=DOTNET_HOME=$api_working_dir
EOF

# -- end setup API service --

# -- deliver --

# deliver source code

git clone https://github.com/launchcodeeducation/coding-events-api /tmp/coding-events-api

cd /tmp/coding-events-api/CodingEventsAPI

# checkout branch that has the appsettings.json we need to connect to the KV
git checkout $solution_branch

dotnet publish -c Release -r linux-x64 -o "$api_working_dir"

# write public IP address to appsettings.json ServerOrigins
sed -i "/ServerOrigin/s/\"\"/\"https:\/\/$(curl https://ipinfo.io/ip -s)\"/" "$api_working_dir/appsettings.json"

# -- end deliver --

# -- deploy --

# start API service
service coding-events-api start

# -- end deploy --