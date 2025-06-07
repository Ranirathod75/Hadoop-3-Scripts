#####################################################
		Hadoop 3 Multi Node
#####################################################


# 1] Update the system
sudo apt-get update && sudo apt-get dist-upgrade -y


# 2] Copy public key on to the DataCenter main server
scp -i dc-key.pem dc-key.pem ubuntu@public_dns:~/.ssh


# 3] Create a Hadoop user for accessing HDFS
sudo addgroup hadoop
sudo adduser hduser --ingroup hadoop 
sudo adduser hduser sudo
sudo su hduser


# 4] Create local key/ Configure SSH
ssh-keygen
cat id_ed25519.pub >> authorized_keys
OR
cat id_rsa.pub >> authorized_keys


# 5] Copy the instance public key (dc-key.pem) to hduser's directory
sudo su
cp /home/ubuntu/.ssh/dc-key.pem /home/hduser/.ssh/
chown hduser:hadoop /home/hduser/.ssh/dc-key.pem
exit


# 6] Install Java 8 (Open-JDK)
sudo apt install openjdk-8-jdk openjdk-8-jre -y
java -version


# 7] Download and Install Hadoop
wget https://dlcdn.apache.org/hadoop/common/stable/hadoop-3.3.5.tar.gz    #get latest stable version
tar -xzvf hadoop-3.3.5.tar.gz
sudo mv hadoop-3.3.5 /usr/local/hadoop
sudo chown -R hduser:hadoop /usr/local/hadoop


# 8] Set Enviornment Variable
nano .bashrc

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/usr/local/hadoop
export PATH=$PATH:$HADOOP_HOME/bin
export PATH=$PATH:$HADOOP_HOME/sbin
export PATH=$PATH:/usr/local/hadoop/bin/
export HADOOP_MAPRED_HOME=$HADOOP_HOME
export HADOOP_COMMON_HOME=$HADOOP_HOME
export HADOOP_HDFS_HOME=$HADOOP_HOME
export YARN_HOME=$HADOOP_HOME
export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop

source .bashrc

cd /usr/local/hadoop/etc/hadoop/


# 9] Update hadoop-env.sh
nano hadoop-env.sh

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_LOG_DIR=/var/log/hadoop

sudo mkdir /var/log/hadoop/
sudo chown -R hduser:hadoop /var/log/hadoop


#### Production Recommended Settings starts here ####


# 10] Disable FireWall iptables(Default Firewalls of Linux)
sudo iptables -L -n
sudo ufw status
sudo ufw disable


# 11] Disabling Transparent Hugepage Compaction
cat /sys/kernel/mm/transparent_hugepage/defrag

$ sudo nano /etc/init.d/disable-transparent-hugepages

#!/bin/sh
### BEGIN INIT INFO
# Provides:          disable-transparent-hugepages
# Required-Start:    $local_fs
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Disable Linux transparent huge pages
# Description:       Disable Linux transparent huge pages, to improve
#                    database performance.
### END INIT INFO

case $1 in
  start)
    if [ -d /sys/kernel/mm/transparent_hugepage ]; then
      thp_path=/sys/kernel/mm/transparent_hugepage
    elif [ -d /sys/kernel/mm/redhat_transparent_hugepage ]; then
      thp_path=/sys/kernel/mm/redhat_transparent_hugepage
    else
      return 0
    fi

    echo 'never' > ${thp_path}/enabled
    echo 'never' > ${thp_path}/defrag

    unset thp_path
    ;;
esac

$ sudo chmod 755 /etc/init.d/disable-transparent-hugepages

$ sudo update-rc.d disable-transparent-hugepages defaults

>>Restart server


# 12] Set Swappiness
sudo sysctl -a | grep vm.swappiness
sudo sysctl vm.swappiness=1


# 13] Configure NTP 
timedatectl status
timedatectl list-timezones
sudo timedatectl set-timezone Asia/Kolkata
sudo apt install ntp -y


## 14] Configure SSH Password less logins for different nodes
sudo su -c touch /home/hduser/.ssh/config; echo "Host *\n StrictHostKeyChecking no\n
UserKnownHostsFile=/dev/null" > /home/hduser/.ssh/config

sudo service ssh restart


# 15] Configure .profile (make sure you are on NN) 
 nano .profile
 eval `ssh-agent` ssh-add /home/hduser/.ssh/dc-key.pem

 source .profile


#### Production Recommended Settings Ends here ####

----------****** Create a snapshot at this point ******-----------------
Create 4 nodes from this image


# 16] Configure hosts
sudo nano /etc/hosts    # include these lines:FQDN  and do this for all the hosts

172.31.29.56 ip-172-31-29-56.ec2.internal nn  # private-ip private-DNS host-name
172.31.27.96 ip-172-31-27-96.ec2.internal rm
172.31.18.137 ip-172-31-18-137.ec2.internal 1dn
172.31.23.79 ip-172-31-23-79.ec2.internal 2dn
172.31.16.236 ip-172-31-16-236.ec2.internal 3dn

Do this for all nodes 


# 18] Install and Configure dsh
sudo apt install dsh -y
sudo nano /etc/dsh/machines.list

#localhost
nn
rm
1dn
2dn
3dn

dsh -a uptime
dsh -a source .profile

cd /usr/local/hadoop/etc/hadoop


# 19] Configure masters and slaves
nano masters
rm

nano workers
1dn
2dn
3dn


# 20] Update core-site.xml (cluster wide operations)
nano core-site.xml
<property>
    <name>fs.defaultFS</name>
    <value>hdfs://nn:9000</value>
  </property>


# 21] Update hdfs-site.xml on name node 
mkdir -p /usr/local/hadoop/data/hdfs/namenode
nano hdfs-site.xml

<property>
    <name>dfs.replication</name>
    <value>3</value>
  </property>
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>file:///usr/local/hadoop/data/hdfs/namenode</value>
  </property>
   <property>
    <name>dfs.datanode.data.dir</name>
    <value>file:///usr/local/hadoop/data/hdfs/datanode</value>
  </property> 


# 22] Create proper directories on datanode's
dsh -m 1dn,2dn,3dn mkdir -p /usr/local/hadoop/data/hdfs/datanode


# 23] Update yarn-site.xml
nano yarn-site.xml

<property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>
  <property>
    <name>yarn.resourcemanager.hostname</name>
    <value>rm</value>
  </property>
<property>
        <name>yarn.nodemanager.env-whitelist</name>
        <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_MAPRED_HOME</value>
  </property>


# 24] Update mapred-site.xml
nano mapred-site.xml

<property>
    <name>mapreduce.jobtracker.address</name>
    <value>rm:54311</value>
  </property>
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
<property>
  <name>yarn.app.mapreduce.am.env</name>
  <value>HADOOP_MAPRED_HOME=$HADOOP_MAPRED_HOME</value>
</property>
<property>
  <name>mapreduce.map.env</name>
  <value>HADOOP_MAPRED_HOME=$HADOOP_MAPRED_HOME</value>
</property>
<property>
  <name>mapreduce.reduce.env</name>
  <value>HADOOP_MAPRED_HOME=$HADOOP_MAPRED_HOME</value>
</property>

sudo chown -R hduser:hadoop $HADOOP_HOME


# 25] SCP all the files
cd /usr/local/hadoop/etc/hadoop
For  rm node #do this for all nodes
scp core-site.xml hdfs-site.xml mapred-site.xml yarn-site.xml workers rm:/usr/local/hadoop/etc/hadoop



# 26] Format Namenode
hdfs namenode -format


# 27] Start the cluster
start-dfs.sh
start-yarn.sh
 
dsh -a jps


hdfs dfs -mkdir /user
hdfs dfs -mkdir /user/ubuntu
hdfs dfs -put hadoop-3.3.4o apt .tar.gz /user/ubuntu
hdfs dfs -ls 
hdfs dfs -ls -R

yarn jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar pi  5 10


>>for NN = 9870
>>for RM = 8088