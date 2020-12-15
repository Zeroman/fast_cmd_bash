# fast_cmd
fast bash command

## 中文
快速编写命令，无需处理参数和文档，添加一个方法cmd_test1
```
模板格式：方法名() { #别名-> 注解

cmd_test1() { # zz-> 测试1
 echo "test1‘
}

执行如下命令都可以执行方法cmd_test1：
./run.sh zz
./run.sh test1
./run.sh t1
./run.sh 1

./run.sh #无参数，显示help
```



## English
Quickly write commands, no need to deal with parameters and documents, add a command test1
```
cmd_test1() {# zz-> test 1
  echo "test1'
}
The method can be executed by executing the following commands:
./run.sh zz
./run.sh test1
./run.sh t1
./run.sh 1
```
