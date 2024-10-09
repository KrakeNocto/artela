echo "Moniker:"
read -r MONIKER

ARTELA_CHAIN_ID=artela_11822-1

min_am=10
max_am=64
random_am=$(shuf -i $min_am-$max_am -n 1)

min_am1=1
max_am1=9
port=$(shuf -i $min_am1-$max_am1 -n 1)

cd $HOME
rm -rf artela
git clone https://github.com/artela-network/artela

#ДОБАВИТЬ СКАЧКУ БИНАРНИКА

/root/go/bin/artelad config node tcp://localhost:2${random_am}57
/root/go/bin/artelad config chain-id artela_11822-1
/root/go/bin/artelad init $MONIKER --chain-id artela_11822-1

wget -O $HOME/.artelad/config/genesis.json https://server-4.itrocket.net/testnet/artela/genesis.json
wget -O $HOME/.artelad/config/addrbook.json  https://server-4.itrocket.net/testnet/artela/addrbook.json

SEEDS="8d0c626443a970034dc12df960ae1b1012ccd96a@artela-testnet-seed.itrocket.net:30656"
PEERS="5c9b1bc492aad27a0197a6d3ea3ec9296504e6fd@artela-testnet-peer.itrocket.net:30656,c25185a411b5f5f653a4bf5410cb3af71ff6a53a@65.108.67.54:3456,866cdfa0596fc40b14b0817f7ed3497c6a17f397@162.55.65.137:15856,d6034b52fe3c20764a7120c23e6a2eadc2caec2b@89.117.56.249:3456,fb5c8db2601a40f858d189b94d873f6121284af4@46.250.224.208:3456,251fc8d9024cd6b6b73738b7d59806968900973a@45.90.123.161:30656,bebae3c6c12b86cb42cf054c58bbab8d4d47b37c@66.248.240.158:32110,4866a0d0ada3995058d36c2c1da1af22c5bc52e6@85.190.246.221:3456,25c27ff91aef70e6345a37b676cfd62cca1f1585@84.247.132.78:30656,412e10bed8ea78a6e53049e13203d800edcfb4c5@165.154.225.22:26656,e5aca0946f1096a63673bc6ab362d8383054cc9d@185.245.183.45:26656,3282eb65bb131fbb00f14afef46ae451a9ea87ff@84.54.23.125:3456,f98c45802e0e756f3e5e06e6cd3259e03182b44a@75.119.154.23:26656,b7a45fd7f5ca197806cb8f194fc31e5ceac4d7ba@109.199.107.164:3456,0f5a4ad942c2bb222362e7cb92f11f0f474a0f6d@45.136.17.29:3456,0172eec239bb213164472ea5cbd96bf07f27d9f2@47.251.14.47:26656,ae42e495df3e9b92b22098cc9208e2f46e04dd96@154.53.61.142:3456,8d198deb0f48dd2e4d0f00b3d4fe1772413171fc@95.217.120.205:15856,60aeda847d1dbcc9b6dccecc7d0978eb9d9c70a4@185.222.240.97:11856,5434b172ae72e625e2131b3b7f2b20c1ab74248f@45.85.250.178:3456,1f8c2a334d4e82fa959e87770a91270af4c2387a@77.237.240.99:3456"
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $HOME/.artelad/config/config.toml

sed -i.bak -e "s%:1317%:${port}17%g;
s%:8080%:${port}80%g;
s%:9090%:${port}90%g;
s%:9091%:${port}91%g;
s%:8545%:${port}45%g;
s%:8546%:${port}46%g;
s%:6065%:${port}65%g" $HOME/.artelad/config/app.toml

sed -i.bak -e "s%:26658%:2${random_am}58%g;
s%:26657%:2${random_am}57%g;
s%:6060%:6${random_am}0%g;
s%:26656%:2${random_am}56%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):2${random_am}56\"%;
s%:26660%:2${random_am}60%g" $HOME/.artelad/config/config.toml

sudo tee /etc/systemd/system/artelad.service > /dev/null <<EOF
[Unit]
Description=Artela node
After=network-online.target
[Service]
User=root
WorkingDirectory=$HOME/.artelad
ExecStart=/root/go/bin/artelad start --home $HOME/.artelad
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

/root/go/bin/artelad tendermint unsafe-reset-all --home $HOME/.artelad
if curl -s --head curl https://server-4.itrocket.net/testnet/artela/artela_2024-10-09_14044070_snap.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
  curl https://server-4.itrocket.net/testnet/artela/artela_2024-10-09_14044070_snap.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.artelad
    else
  echo "no snapshot founded"
fi

rm artela_install.sh

sudo systemctl daemon-reload
sudo systemctl enable artelad
sudo systemctl restart artelad && sudo journalctl -u artelad -f
