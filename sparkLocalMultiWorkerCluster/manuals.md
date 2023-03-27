# 參考資源

* [設定Path](https://sparkbyexamples.com/spark/apache-spark-installation-on-windows/)
* [下載hadoop winutils](https://github.com/kontext-tech/winutils)
* [安裝hadoop winutils](https://kontext.tech/article/825/hadoop-331-winutils)

# 步驟

安裝java sdk / jdk 19
安裝 JRE 8 / jre1.8.0_351
下載pyspark解壓
下載hadoop winutils解壓
設定環境變數（參照上述設定Path網頁部分）
重開機
docker compose，選擇掛載conf、jars等目錄

# 調整 Jars

## 步驟

* 清空jars資料夾
* 複製jars_from_image資料夾的內容到jars資料夾
* 下載下面的maven setup jars之後，覆蓋到jars資料夾裡面

## jars maven setup

<dependency>
    <groupId>org.apache.hadoop</groupId>
    <artifactId>hadoop-common</artifactId>
    <version>3.3.1</version>
</dependency>
<dependency>
    <groupId>org.apache.hadoop</groupId>
    <artifactId>hadoop-client</artifactId>
    <version>3.3.1</version>
</dependency>
<dependency>
    <groupId>org.apache.hadoop</groupId>
    <artifactId>hadoop-aws</artifactId>
    <version>3.3.1</version>
</dependency>
<dependency>
    <groupId>org.apache.spark</groupId>
    <artifactId>spark-core_2.12</artifactId>
    <version>3.3.1</version>
</dependency>
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-core</artifactId>
    <version>2.13.0</version>
</dependency>
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-annotations</artifactId>
    <version>2.13.0</version>
</dependency>
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-databind</artifactId>
    <version>2.13.0</version>
</dependency>
<dependency>
   <groupId>com.microsoft.sqlserver</groupId>
   <artifactId>mssql-jdbc</artifactId>
   <version>7.2.2.jre8</version>
</dependency>
<dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
    <version>42.5.1</version>
</dependency>