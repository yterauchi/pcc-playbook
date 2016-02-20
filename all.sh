#!/bin/sh

echo "start date"
date
ansible-playbook pcc_server_build.yml
ansible-playbook pcc_source_build.yml
ansible-playbook pcc_tutorial.yml

echo "finished."
echo ""
echo "zabbix GUIで初期セットアップ&APIユーザ作成&監視テンプレートインポート"
echo "https://<IPaddress>/zabbix/"
echo "ユーザ名：Admin"
echo "パスワード:zabbix"

echo ""
echo "その後、"
echo "  ansible-playbook pcc_user.yml"
echo "を実行"

echo ""
echo "PCC URL"
echo "  https://<IPaddress>/auto-web"

date
