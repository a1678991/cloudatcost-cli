# cloudatcost-cli
##bash based cloudatcost api client

    cloudatcost.sh -h

### Require jq(https://stedolan.github.io/jq/)  
Package will be available in major distribution

### Environment variables  
All options available in shell can be passed in as environment variables.

Environment variable | Description
-------------------- | -----------
MAIL                 | Mailaddress
KEY                  | API key
-------------------- | -----------
OPETYPE              | Operation type ex. b,r,
-------------------- | -----------
DC                   | Datacenter
OS                   | Operating system ex. 9,14,42
CPU                  | CPU size
RAM                  | RAM size (MB)
STORAGE              | Storage size (GB)

consoleはAPIがちゃんと返事してくれないので動きません  
~~buildもAPIが壊れているので動きません~~→復活したみたいです
