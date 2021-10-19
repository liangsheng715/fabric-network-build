package main

import (
	"NetworkBuilding/application/sdk"
	"bytes"
	"fmt"

	"github.com/gin-gonic/gin"
)

func main() {
	router := gin.Default()
	sdk.Init()
	router.GET("/testGet", func(context *gin.Context) {
		fcn := context.Query("fcn")
		arg1 := context.Query("arg1")
		resp, err := sdk.ChannelQuery(fcn, [][]byte{
			[]byte(arg1),
		})
		if err != nil {
			fmt.Println(err.Error())
			return
		}
		context.JSON(int(resp.ChaincodeStatus), bytes.NewBuffer(resp.Payload).String())
	})
	router.POST("/testPost", func(context *gin.Context) {
		fcn := context.PostForm("fcn")
		arg1 := context.PostForm("arg1")
		arg2 := context.PostForm("arg2")
		arg3 := context.PostForm("arg3")
		resp, err := sdk.ChannelExecute(fcn, [][]byte{
			[]byte(arg1),
			[]byte(arg2),
			[]byte(arg3),
		})
		if err != nil {
			fmt.Println(err.Error())
			return
		}
		context.JSON(int(resp.ChaincodeStatus), bytes.NewBuffer(resp.Payload).String())
	})
	err := router.Run(":8080")
	if err != nil {
		fmt.Println(err.Error())
		return
	}
}
