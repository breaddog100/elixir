#!/bin/bash


# 设置版本号
current_version=20240916001

update_script() {
    # 指定URL
    update_url="https://raw.githubusercontent.com/breaddog100/elixir/main/elixir.sh"
    file_name=$(basename "$update_url")

    # 下载脚本文件
    tmp=$(date +%s)
    timeout 10s curl -s -o "$HOME/$tmp" -H "Cache-Control: no-cache" "$update_url?$tmp"
    exit_code=$?
    if [[ $exit_code -eq 124 ]]; then
        echo "命令超时"
        return 1
    elif [[ $exit_code -ne 0 ]]; then
        echo "下载失败"
        return 1
    fi

    # 检查是否有新版本可用
    latest_version=$(grep -oP 'current_version=([0-9]+)' $HOME/$tmp | sed -n 's/.*=//p')

    if [[ "$latest_version" -gt "$current_version" ]]; then
        clear
        echo ""
        # 提示需要更新脚本
        printf "\033[31m脚本有新版本可用！当前版本：%s，最新版本：%s\033[0m\n" "$current_version" "$latest_version"
        echo "正在更新..."
        sleep 3
        mv $HOME/$tmp $HOME/$file_name
        chmod +x $HOME/$file_name
        exec "$HOME/$file_name"
    else
        # 脚本是最新的
        rm -f $tmp
    fi

}

# 部署节点
function install_node() {

    # 运行参数
    read -p "节点名称: " VALIDATOR_NAME
    read -p "EVM钱包地址: " SAFE_PUBLIC_ADDRESS
    read -p "EVM钱包私钥: " PRIVATE_KEY

    # 检查并去掉PRIVATE_KEY中的0x前缀
    if [[ "$PRIVATE_KEY" == 0x* ]]; then
        PRIVATE_KEY=${PRIVATE_KEY:2}
    fi

    # 创建validator.env
    cat <<EOF > validator.env
ENV=testnet-3
# Allowed characters A-Z, a-z, 0-9, _, -, and space
STRATEGY_EXECUTOR_DISPLAY_NAME=$VALIDATOR_NAME
STRATEGY_EXECUTOR_BENEFICIARY=$SAFE_PUBLIC_ADDRESS
SIGNER_PRIVATE_KEY=$PRIVATE_KEY
EOF

    # 安装Docker
	if ! command -v docker &> /dev/null; then
	    echo "Docker未安装，正在安装..."
	    # 更新包列表
	    sudo apt-get update
	    # 安装必要的包
	    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
	    # 添加Docker的官方GPG密钥
	    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker.gpg
	    # 添加Docker的APT仓库
	    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
	    # 再次更新包列表
	    sudo apt-get update
	    # 安装Docker
	    sudo apt-get install -y docker-ce
	    echo "Docker安装完成。"
	else
	    echo "Docker已安装。"
	fi
	
	sudo groupadd docker
	sudo usermod -aG docker $USER

    # 拉取项目镜像
    sudo docker pull elixirprotocol/validator:v3
    sudo docker run -it -d --env-file validator.env --name elixir elixirprotocol/validator:v3

    echo "部署完成..."
}

# 查看日志
function view_logs() {
    sudo docker logs -f elixir
}

# 启动节点
function start_node(){
    sudo docker run -it -d --env-file validator.env --name elixir elixirprotocol/validator:v3
}

# 停止节点
function stop_node(){
    sudo docker stop elixir
}

# 升级节点
function update_node(){
    sudo docker kill elixir
    sudo docker rm elixir
    sudo docker pull elixirprotocol/validator:v3
}

# 卸载节点
function uninstall_node() {
    echo "确定要卸载验证节点吗？[Y/N]"
    read -r -p "请确认: " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            echo "开始卸载验证节点..."
            stop_node
            sudo docker rm -f elixir && docker rmi elixir
            echo "验证节点卸载完成。"
            ;;
        *)
            echo "取消卸载操作。"
            ;;
    esac
}

# 菜单
function main_menu() {
	while true; do
	    clear
	    echo "======================= Elixir 一键部署脚本======================="
		echo "当前版本：$current_version"
		echo "沟通电报群：https://t.me/lumaogogogo"
		echo "推荐配置：4C8G100G"
	    echo "请选择要执行的操作:"
	    echo "1. 部署节点 install_node"
	    echo "2. 查看日志 view_logs"
        echo "3. 启动节点 start_node"
        echo "4. 停止节点 stop_node"
        echo "5. 升级节点 update_node"
	    echo "1618. 卸载节点 uninstall_node"
	    echo "0. 退出脚本 exit"
	    read -p "请输入选项: " OPTION
	
	    case $OPTION in
	    1) install_node ;;
	    2) view_logs ;;
        3) start_node ;;
        4) stop_node ;;
        5) update_node ;;
	    1618) uninstall_node ;;
	    0) echo "退出脚本。"; exit 0 ;;
	    *) echo "无效选项，请重新输入。"; sleep 3 ;;
	    esac
	    echo "按任意键返回主菜单..."
        read -n 1
    done
}

# 检查更新
update_script

# 运行菜单
main_menu