#####################################################
		Hadoop 3 Single Node
#####################################################



# 1] INSTALL JAVA
sudo apt-get update
sudo apt install openjdk-8-jdk openjdk-8-jre -y
sudo apt update
sudo apt install openjdk-8-jdk openjdk-8-jre -y

java -version   #to check java is installed or not


# 2] CREATE A HADOOP USER FOR ACCESSING HDFS AND MAP-REDUCE
sudo addgroup hadoop
sudo adduser hduser --ingroup hadoop 
sudo adduser hduser sudo
sudo su hduser


# 3] CONFIGURE PASSWORDLESS SSH FOR LOCALHOST
ssh-keygen
cd .ssh
cat id_rsa.pub >> authorized_keys
ssh localhost


# 4] DOWNLOAD HADOOP
wget https://dlcdn.apache.org/hadoop/common/stable/hadoop-3.4.1.tar.gz   #always download stable version of hadoop


# 5] EXTRACT AND INSTALL HADOOP TAR BALL
tar -xzvf hadoop-3.4.1.tar.gz
sudo mv hadoop-3.4.1 /usr/local/hadoop
sudo chown hduser:hadoop -R /usr/local/hadoop


# 6] SET ENVIRONMENT VARIABLES
nano .bashrc     #file where you can configure your environment varibales

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

source .bashrc       #to refresh the file


cd /usr/local/hadoop/etc/hadoop/

# 7] HADOOP LEVEL CONFIGURATION

# i] hadoop-env.sh :- 
nano hadoop-env.sh

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_LOG_DIR=/var/log/hadoop

sudo mkdir /var/log/hadoop
sudo chown hduser:hadoop -R /var/log/hadoop

# ii] Update core-site.xml :- 
nano core-site.xml

<property>
  <name>fs.defaultFS</name>
  <value>hdfs://localhost:54310</value>
</property>

# iii] Update mapred-site.xml :- 
nano mapred-site.xml

<property>
  <name>mapreduce.jobtracker.address</name>
  <value>localhost:54311</value>
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

# iv] Update hdfs-site.xml :- 
sudo mkdir -p /usr/local/hadoop_store/hdfs/namenode
sudo mkdir -p /usr/local/hadoop_store/hdfs/datanode
sudo chown -R hduser:hadoop /usr/local/hadoop_store

nano hdfs-site.xml

<property> 
<name>dfs.replication</name>
  <value>1</value>
 </property>
 <property>
   <name>dfs.namenode.name.dir</name>
   <value>file:/usr/local/hadoop_store/hdfs/namenode</value>
 </property>
 <property>
   <name>dfs.datanode.data.dir</name>
   <value>file:/usr/local/hadoop_store/hdfs/datanode</value>
 </property>

# v] Update yarn-site.xml :- 
nano yarn-site.xml

<property>
      <name>yarn.nodemanager.aux-services</name>
      <value>mapreduce_shuffle</value>
   </property>
<property>
        <name>yarn.nodemanager.env-whitelist</name>
        <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_MAPRED_HOME</value>
</property>


# 8] FORMAT NAMENODE
hdfs namenode -format


# 9] START TWO SERVICES HDFS AND YARN
start-dfs.sh
start-yarn.sh


jps

NN = 9870
