# Local Jenkins Update Site Mirror
Set of scripts to deploy a local Jenkins Update Site Mirror with Nginx

---

## OVERVIEW

* Install Docker (docker-ce)
* Prepare a disk partition with at least **50GB** of available disk space ( which will receive the mirrored plugins )
* Clone this repository
* Execute the initial sync script
* Start Nginx proxy using docker-compose
* Your Jenkins Update Site will be available at **http://CUSTOM-JENKINS-SITE-FQDN/update-center.json**

## INITIAL SYNC

```sh
$ cd mirror_jenkins_uc
$ ./mirror_jenkins_uc.sh /jenkins-ci-updates jenkins.example.com
```

## START NGINX PROXY

* Prior to run docker-compose, make sure to update the **docker-compose.yml** file with the proper volume mapping, replacing the placeholder **\_\_LOCAL\_MIRROR\_PATH\_\_**

```sh
$ cd mirror_jenkins_uc/compose
$ docker-compose -p uc-proxy up -d
```

## NOTES
* The initial sync downloads all available plugins/plugin versions from **updates.jenkins.io**
* Initial sync can take hours to finish, so grab a coffee and relax
* We are using wget with **mirror (-m)** option. More information can be found here: https://www.gnu.org/software/wget/manual/wget.html
* Feel free to add the script in a cron job to automatically run the sync

---

If you have any questions, please contact the our Support Department at **support@cloud44.io**
