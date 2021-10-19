因使用了go mod 管理项目依赖，所以需golang版本为1.13以上。

请自行百度go mod 的相关设置。

拉取项目后请在 NetworkBuilding 目录下执行 go mod tidy 命令拉取相关依赖。



项目最新提交记录，使用fabric 1.4.11版本，golang 1.16.3，开启了TLS，etcdraft共识。

请自行使用 git 查看代码提交记录，查看修改了那些内容。



使用golang的GIN框架，搭建了一个简单web服务，存放在NetworkBuilding/application目录下，请自行使用postman测试相应接口。



项目启动流程：

```linux
cd NetworkBuilding
./start.sh
cd application
go build
./application
```



http请求访问：

```shell
curl -X POST -H 'Content-Type: application/x-www-form-urlencoded' -i http://localhost:8080/testPost --data 'fcn=invoke&arg1=a&arg2=b&arg3=10'

curl -X GET -i 'http://localhost:8080/testGet?fcn=query&arg1=a'
```

