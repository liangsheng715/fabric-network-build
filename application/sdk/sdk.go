package sdk

import (
	"github.com/hyperledger/fabric-sdk-go/pkg/client/channel"
	"github.com/hyperledger/fabric-sdk-go/pkg/core/config"
	"github.com/hyperledger/fabric-sdk-go/pkg/fabsdk"
)

// sdk相关配置
var (
	SDK           *fabsdk.FabricSDK     // Fabric提供的SDK
	ChannelName   = "mychannel"         // 通道名称
	ChaincodeName = "mychaincode"       // 链码名称
	Org           = "Org1"              // 组织
	User          = "Admin"             // 用户
	ConfigPath    = "./config_e2e.yaml" // 配置文件路径
)

// Init sdk初始化
func Init() {
	var err error
	// 通过配置文件初始化SDK
	SDK, err = fabsdk.New(config.FromFile(ConfigPath))
	if err != nil {
		panic(err)
	}
}

// ChannelExecute 区块链交互
func ChannelExecute(fcn string, args [][]byte) (channel.Response, error) {
	// 创建客户端，表明在通道的身份
	ctx := SDK.ChannelContext(ChannelName, fabsdk.WithOrg(Org), fabsdk.WithUser(User))
	cli, err := channel.New(ctx)
	if err != nil {
		return channel.Response{}, err
	}

	// 对区块链增删改的操作（调用了链码的invoke）
	resp, err := cli.Execute(channel.Request{
		ChaincodeID: ChaincodeName,
		Fcn:         fcn,
		Args:        args,
	}, channel.WithTargetEndpoints("node1.organization1.example.com", "node1.organization2.example.com", "node1.organization3.example.com"))

	if err != nil {
		return channel.Response{}, err
	}

	// 返回链码执行后的结果
	return resp, nil
}

// ChannelQuery 区块链查询
func ChannelQuery(fcn string, args [][]byte) (channel.Response, error) {
	// 同上
	ctx := SDK.ChannelContext(ChannelName, fabsdk.WithOrg(Org), fabsdk.WithUser(User))
	cli, err := channel.New(ctx)
	if err != nil {
		return channel.Response{}, err
	}

	// 对区块链查询的操作（调用了链码的invoke），将结果返回
	return cli.Query(channel.Request{
		ChaincodeID: ChaincodeName,
		Fcn:         fcn,
		Args:        args,
	}, channel.WithTargetEndpoints("node1.organization1.example.com", "node1.organization2.example.com", "node1.organization3.example.com"))
}
