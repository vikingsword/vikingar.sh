#!/usr/bin/env bash

export LANG=en_US.UTF-8

echoType='echo -e'

echoContent() {
    case $1 in
        # 红色
    "red")
        ${echoType} "\033[31m${printN}$2 \033[0m"
        ;;
        # 天蓝色
    "skyBlue")
        ${echoType} "\033[1;36m${printN}$2 \033[0m"
        ;;
        # 绿色
    "green")
        ${echoType} "\033[32m${printN}$2 \033[0m"
        ;;
        # 白色
    "white")
        ${echoType} "\033[37m${printN}$2 \033[0m"
        ;;
    "magenta")
        ${echoType} "\033[31m${printN}$2 \033[0m"
        ;;
        # 黄色
    "yellow")
        ${echoType} "\033[33m${printN}$2 \033[0m"
        ;;

        # 亮绿色
    "lightGreen")
        ${echoType} "\033[32m${printN}$2 \033[0m"
        ;;
        # 亮黄色
    "lightYellow")
        ${echoType} "\033[1;33m${printN}$2 \033[0m"
        ;;
    "lightBlue")
        # 水蓝色 (亮蓝色)
        ${echoType} "\033[36m${printN}$2 \033[0m"
        ;;
    "lightMagenta")
        # 粉红色 (亮紫色)
        ${echoType} "\033[35m${printN}$2 \033[0m"
        ;;
    "lightRed")
        # 亮红色
        ${echoType} "\033[31m${printN}$2 \033[0m"
        ;;
    esac
}

checkSystem() {
    if [[ -n $(find /etc -name "redhat-release") ]] || grep </proc/version -q -i "centos"; then
        mkdir -p /etc/yum.repos.d

        if [[ -f "/etc/centos-release" ]]; then
            centosVersion=$(rpm -q centos-release | awk -F "[-]" '{print $3}' | awk -F "[.]" '{print $1}')

            if [[ -z "${centosVersion}" ]] && grep </etc/centos-release -q -i "release 8"; then
                centosVersion=8
            fi
        fi

        release="centos"
        installType='yum -y install'
        removeType='yum -y remove'
        upgrade="yum update -y --skip-broken"
        checkCentosSELinux
    elif [[ -f "/etc/issue" ]] && grep </etc/issue -q -i "debian" || [[ -f "/proc/version" ]] && grep </etc/issue -q -i "debian" || [[ -f "/etc/os-release" ]] && grep </etc/os-release -q -i "ID=debian"; then
        release="debian"
        installType='apt -y install'
        upgrade="apt update"
        updateReleaseInfoChange='apt-get --allow-releaseinfo-change update'
        removeType='apt -y autoremove'

    elif [[ -f "/etc/issue" ]] && grep </etc/issue -q -i "ubuntu" || [[ -f "/proc/version" ]] && grep </etc/issue -q -i "ubuntu"; then
        release="ubuntu"
        installType='apt -y install'
        upgrade="apt update"
        updateReleaseInfoChange='apt-get --allow-releaseinfo-change update'
        removeType='apt -y autoremove'
        if grep </etc/issue -q -i "16."; then
            release=
        fi
    fi

    if [[ -z ${release} ]]; then
        echoContent red "\n本脚本不支持此系统, 请将下方日志反馈给开发者\n"
        echoContent yellow "$(cat /etc/issue)"
        echoContent yellow "$(cat /proc/version)"
        exit 0
    fi
}

# 初始化安装目录
mkdirTools() {
    mkdir -p /etc/vikingar
}

# test
# 安装工具包
installTools() {
    echoContent skyBlue "\n进度  $1/${totalProgress} : 安装工具"
    # 修复ubuntu个别系统问题
    if [[ "${release}" == "ubuntu" ]]; then
        dpkg --configure -a
    fi

    if [[ -n $(pgrep -f "apt") ]]; then
        pgrep -f apt | xargs kill -9
    fi

    echoContent green " ---> 检查、安装更新"
    echoContent green " --->【如果长时间无反应，请手动停止后重新执行】"

    # 确保 yum 命令可以顺利执行，先删除锁文件。这样可以避免因前一个 yum 进程意外结束而导致的锁定。
    if [[ "${release}" == "centos" ]]; then
        rm -rf /var/run/yum.pid
        ${installType} epel-release >/dev/null 2>&1
    fi

    if ! find /usr/bin /usr/sbin | grep -q -w wget; then
        echoContent green " ---> 安装wget"
        ${installType} wget >/dev/null 2>&1
    fi

    if ! find /usr/bin /usr/sbin | grep -q -w curl; then
        echoContent green " ---> 安装curl"
        ${installType} curl >/dev/null 2>&1
    fi

    if ! find /usr/bin /usr/sbin | grep -q -w unzip; then
        echoContent green " ---> 安装unzip"
        ${installType} unzip >/dev/null 2>&1
    fi

    if ! find /usr/bin /usr/sbin | grep -q -w socat; then
        echoContent green " ---> 安装socat"
        ${installType} socat >/dev/null 2>&1
    fi

    if ! find /usr/bin /usr/sbin | grep -q -w tar; then
        echoContent green " ---> 安装tar"
        ${installType} tar >/dev/null 2>&1
    fi

    if ! find /usr/bin /usr/sbin | grep -q -w cron; then
        echoContent green " ---> 安装crontabs"
        if [[ "${release}" == "ubuntu" ]] || [[ "${release}" == "debian" ]]; then
            ${installType} cron >/dev/null 2>&1
        else
            ${installType} crontabs >/dev/null 2>&1
        fi
    fi

    if ! find /usr/bin /usr/sbin | grep -q -w jq; then
        echoContent green " ---> 安装jq"
        ${installType} jq >/dev/null 2>&1
    fi

    if ! find /usr/bin /usr/sbin | grep -q -w binutils; then
        echoContent green " ---> 安装binutils"
        ${installType} binutils >/dev/null 2>&1
    fi

    if ! find /usr/bin /usr/sbin | grep -q -w ping6; then
        echoContent green " ---> 安装ping6"
        ${installType} inetutils-ping >/dev/null 2>&1
    fi

    # 生成二维码的工具
    # if ! find /usr/bin /usr/sbin | grep -q -w qrencode; then
    #     echoContent green " ---> 安装qrencode"
    #     ${installType} qrencode >/dev/null 2>&1
    # fi

    if ! find /usr/bin /usr/sbin | grep -q -w sudo; then
        echoContent green " ---> 安装sudo"
        ${installType} sudo >/dev/null 2>&1
    fi

    if ! find /usr/bin /usr/sbin | grep -q -w lsb-release; then
        echoContent green " ---> 安装lsb-release"
        ${installType} lsb-release >/dev/null 2>&1
    fi

    if ! find /usr/bin /usr/sbin | grep -q -w lsof; then
        echoContent green " ---> 安装lsof"
        ${installType} lsof >/dev/null 2>&1
    fi

    if ! find /usr/bin /usr/sbin | grep -q -w dig; then
        echoContent green " ---> 安装dig"
        if echo "${installType}" | grep -q -w "apt"; then
            ${installType} dnsutils >/dev/null 2>&1
        elif echo "${installType}" | grep -q -w "yum"; then
            ${installType} bind-utils >/dev/null 2>&1
        fi
    fi
}

# 检查端口是否被占用
checkPort() {
    if [[ -n "$1" ]] && lsof -i "tcp:$1" | grep -q LISTEN; then
        echoContent red "\n ===>> $1 端口被占用，请手动释放后再安装\n"
        lsof -i "tcp:$1" | grep LISTEN
        exit 0
    fi
}

# 获取公网IP
getPublicIP() {
    local type=4
    if [[ -n "$1" ]]; then
        type=$1
    fi
    
    local currentIP=
    currentIP=$(curl -s "-${type}" http://www.cloudflare.com/cdn-cgi/trace | grep "ip" | awk -F "[=]" '{print $2}')
    if [[ -z "${currentIP}" && -z "$1" ]]; then
        currentIP=$(curl -s "-6" http://www.cloudflare.com/cdn-cgi/trace | grep "ip" | awk -F "[=]" '{print $2}')
    fi
    echo "${currentIP}"
}

publicIP=$(getPublicIP "${type}")

# 更新脚本
updateVikingar() {
    echoContent skyBlue "\n进度  $1/${totalProgress} : 更新vikingar脚本"
    rm -rf /etc/vikingar/vikingar.sh
    
    wget -c -q "${wgetShowProgressStatus}" -P /etc/vikingar/ -N --no-check-certificate " https://raw.githubusercontent.com/vikingsword/vikingar.sh/master/vikingar.sh"
    

    sudo chmod 700 /etc/vikingar/vikingar.sh
    local version
    version=$(grep '当前版本: v' "/etc/vikingar/vikingar.sh" | awk -F "[v]" '{print $2}' | tail -n +2 | head -n 1 | awk -F "[\"]" '{print $1}')

    echoContent green "\n ---> 更新完毕"
    echoContent yellow " ---> 请手动执行[vikingar]打开脚本"
    echoContent green " ---> 当前版本：${version}\n"
    echoContent yellow "如更新不成功，请手动执行下面命令\n"
    echoContent skyBlue "wget -N --no-check-certificate  https://raw.githubusercontent.com/vikingsword/vikingar.sh/master/vikingar.sh && chmod 700 ./vikingar.sh && ./vikingar.sh"
    echo
    exit 0
}

# 检测安装内容
checkContainer() {
    # 定义容器名称
    CONTAINER_NAME=$1

    # 获取容器状态
    STATUS=$(docker inspect --format="{{.State.Status}}" $CONTAINER_NAME 2>/dev/null)

    # 检查 'docker inspect' 命令的退出状态来确定容器是否存在
    if [ $? -eq 1 ]; then
        # echo "容器 '$CONTAINER_NAME' 尚未安装."
        # 跳过，不输出
        :
    else
        # 根据状态打印消息
        case $STATUS in
            'running')
                echoContent yellow " =>> 容器 '$CONTAINER_NAME' 正在运行."
                ;;
            'paused')
                echoContent yellow " =>> 容器 '$CONTAINER_NAME' 已暂停."
                ;;
            'exited')
                echoContent yellow " =>> 容器 '$CONTAINER_NAME' 已停止."
                ;;
            *)
                echoContent yellow " =>> 容器 '$CONTAINER_NAME' 处于未知状态: $STATUS"
                ;;
        esac
    fi
}

# 更新服务器系统
updateSystem() {
    if [[ "${release}" == "debian" ]]; then
        sudo apt update && sudo apt upgrade -y

    elif [[ "${release}" == "ubuntu" ]]; then
        sudo apt update && sudo apt upgrade -y

    elif [[ "${release}" == "centos" ]]; then
        sudo yum update -y && sudo yum upgrade -y
    fi
}

# 安装docker和docker-compose
installDocker(){
    echoContent yellow " ---> 安装docker"
    curl -fsSL https://get.docker.com | sh

    echoContent yellow " ---> 安装docker-compose"
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

}

# 检测docker是否安装
checkDocker(){
    if command -v docker &> /dev/null
    then
        echo "Docker 已经安装"
        docker --version
    else
        echo "Docker 没有安装，请先安装"
    fi  
}


#安装nginx proxy manager
installNPM(){
    read -p "输入Nginx Proxy Manager使用的端口 [默认: 81]: " userPort
    if [[ -z "$userPort" ]]; then
        echoContent yellow "未输入, 使用默认端口81"
        userPort=81
    elif ! [[ $userPort =~ ^[0-9]+$ ]]; then
        echoContent red "无效端口: 端口必须是数字."
        return 1
    elif ((userPort < 1 || userPort > 65535)); then
        echoContent red "无效端口：端口必须在 1 与 65535 之间."
        return 1
    fi

    checkPort 80
    checkPort 443
    checkPort $userPort
    checkDocker

    echoContent yellow " ---> 安装Nginx Proxy Manager"
    docker run -d \
        --restart=always \
        --name vikingar-NPM \
        -p 80:80 \
        -p $userPort:81 \
        -p 443:443 \
        -v $(pwd)/data:/data \
        -v $(pwd)/letsencrypt:/etc/letsencrypt \
        jc21/nginx-proxy-manager:latest

    echoContent yellow " ---> Nginx Proxy Manager安装完成"
    echoContent yellow " ---> 访问此处即可使用: " && echoContent green "$(getPublicIP):$userPort"
    echoContent yellow " ---> 默认账号: admin@example.com"
    echoContent yellow " ---> 默认密码: changeme"
}

# 删除nginx proxy manager
uninstallNPM(){
    echoContent yellow " ---> 正在停止Nginx Proxy Manager"
    docker stop vikingar-NPM

    echoContent yellow " ---> 正在删除Nginx Proxy Manager"
    docker rm vikingar-NPM
}

# 脚本快捷方式
aliasInstall() {

    if [[ -f "./vikingar.sh" ]] && [[ -d "/etc/vikingar" ]] && grep <"./vikingar.sh" -q "作者: vikingar"; then
        mv "./vikingar.sh" /etc/vikingar/vikingar.sh
        local vikingarType=
        if [[ -d "/usr/bin/" ]]; then
            if [[ ! -f "/usr/bin/vikingar" ]]; then
                ln -s /etc/vikingar/vikingar.sh /usr/bin/vikingar
                chmod 700 /usr/bin/vikingar
                vikingarType=true
            fi

            rm -rf "./vikingar.sh"
        elif [[ -d "/usr/sbin" ]]; then
            if [[ ! -f "/usr/sbin/vikingar" ]]; then
                ln -s /etc/vikingar/vikingar.sh /usr/sbin/vikingar
                chmod 700 /usr/sbin/vikingar
                vikingarType=true
            fi
            rm -rf "./vikingar.sh"
        fi
        if [[ "${vikingarType}" == "true" ]]; then
            echoContent green "快捷方式创建成功，可执行[vikingar]重新打开脚本"
        fi
    fi
}

# 安装BBR
bbrInstall() {
    echoContent skyBlue "\n--------------------------------------"
    echoContent green "引用地址(https://github.com/ylx2016/Linux-NetSpeed)"
    echoContent yellow "1.继续 (推荐原版BBR+FQ)"
    echoContent yellow "2.返回主菜单"
    echoContent skyBlue "--------------------------------------"
    read -r -p "请选择:" installBBRStatus
    if [[ "${installBBRStatus}" == "1" ]]; then
        wget -N --no-check-certificate "https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh
    else
        menu
    fi
}

# 卸载脚本
unInstall() {
    read -r -p "是否确认卸载安装内容？[y/n]:" unInstallStatus
    if [[ "${unInstallStatus}" != "y" ]]; then
        echoContent green " ---> 放弃卸载"
        menu
        exit 0
    fi
    # echoContent yellow " ---> 脚本不会删除acme相关配置，删除请手动执行 [rm -rf /root/.acme.sh]"
    
    rm -rf /etc/vikingar

    rm -rf /usr/bin/vikingar
    rm -rf /usr/sbin/vikingar
    echoContent green " ---> 卸载快捷方式完成"
    echoContent green " ---> 卸载vikingar脚本完成"
}

# 主菜单
menu() {
    # cd "$HOME" || exit
    echoContent skyBlue "\n=========================================================="
    echoContent lightYellow "vikingar 一键脚本"
    echoContent lightYellow "author: vikingar"
    echoContent lightYellow "version: v1.0"
    echoContent lightYellow "blog: blog.vikingsword.top"
    echoContent skyBlue "=========================================================="

    checkContainer "vikingar-NPM"
    # showInstallStatus
    # checkWgetShowProgress
    
    echoContent skyBlue "\n-------------------------主机-----------------------------"
    echoContent yellow "(1) 主机配置及IP地址"
    echoContent yellow "(2) 更新服务器系统"
    echoContent yellow "(3) BBR算法加速网速 DD重装系统"

    echoContent skyBlue "-------------------------工具-----------------------------"
    echoContent yellow "(4) 安装常用工具"
    echoContent yellow "(5) 安装docker和docker-compose"
    echoContent yellow "(6) 安装Nginx Proxy Manager"
    echoContent yellow "(7) 卸载Nginx Proxy Manager"

    echoContent skyBlue "-------------------------管理-----------------------------"
    echoContent yellow "(8) 卸载脚本"
    echoContent yellow "(0) 更新脚本"
    echoContent yellow "(t) 退出脚本"

    mkdirTools
    aliasInstall

    read -r -p "请选择:" selectInstallType
    case ${selectInstallType} in
    1)
        echo "查询系统信息..."
        uname -a
        lsb_release -a
        
        echoContent yellow " ---> 本机IPv4: " && echoContent green "$(getPublicIP "4")"
        echoContent yellow " ---> 本机IPv6: " && echoContent green "$(getPublicIP "6")"
        ;;
    2)
        checkSystem
        updateSystem
        ;;
    3)
        bbrInstall
        ;;
    4)
        installTools
        ;;
    5)
        installDocker
        ;;
    6)
        installNPM
        ;;
    7)
        uninstallNPM
        ;;
    8)
        unInstall
        ;;
    0)
        updateVikingar
        ;;
    [tT])
        exit 0
        ;;
    *)
        echo "无效的选择"
        ;;
    esac
}

menu
