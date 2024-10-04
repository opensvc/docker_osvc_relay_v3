# Requirements

- **Docker** installed

# Description

This container contains a OpenSVC agent configured as a heartbeat relay.

A relay is usually deployed on a third site.

A two-nodes OpenSVC cluster stretched over 2 datacenters, configured to use a 3rd site relay, avoids the split brain situation when the communication between the nodes are broken, as the relay heartbeat is still operational.

# Build 

Clone this repository, then run the following command in the project directory:

```
docker build -t relay-v3 . 
```
