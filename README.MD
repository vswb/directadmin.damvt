Hướng dẫn cài đặt Directadmin Nulled version 1.62.x

– Chào các bạn hôm nay mình xin hướng đẫn các bạn cài đặt Directadmin Nulled cho Centos 6,7,8 version 1.62.x

Directadmin Nulled và Directadmin bản quyền khác nhau rất nhiều.
Directadmin Nulled chứa rất nhiều nguy cơ và không ổn định. Mình khuyên đối với các bạn làm doanh nghiệp cần sử dụng ổn định thì không nên sử dụng. Còn nếu chia ra để nhiều người quen cùng dùng chung ( ví dụ như bạn và 1 vài người khác góp tiền mua VPS, sau đó muốn tách vps thành nhiều shared hosting ) thì có lẽ đây là sự lựa chọn rất khả quan.
Tiến hành tải file setup về cài đặt tự động

– Tiến hành cài đặt các package và tải script cài đặt tự động

```bash
# yum -y install net-tools network-scripts wget perl epel-release
# wget https://raw.githubusercontent.com/vswb/directadmin.damvt/main/setup.sh
# chmod +x setup.sh
# sh setup.sh
– Nhập ID và license id con số bất kỳ bạn thích:
```

+ Đây là mẫu thông tin mình điền với Centos 6 và 7:

Would you like to install these required pre-install packages? (y/n): y
Please enter your Client ID : 12345
Please enter your License ID : 54321
Enter your hostname (FQDN) : server.system.info.vn
Is this correct? (y,n) : y
Is ens33 your network adaptor with the license IP (10.10.10.5)? (y,n) :y
Is 10.10.10.5 the IP in your license? (y,n) : y
Is this correct? (must match license) (y,n) : y
Would you like the default settings of apache 2.4 with mod_ruid2 and php 7.4 cli? (y/n): y
Would you like to search for the fastest download mirror? (y/n): y
+ Đây là mẫu thông tin mình điền với Centos 8:


Enter your hostname (FQDN) :
Client ID: 12345
License ID: 54321
Hostname: server.system.info.vn
Is this correct? (y,n) : y
Is ens33 your network adaptor with the license IP (10.10.10.5)? (y,n) : y
Your external IP: xxx.xxx.xxx.xxx
The external IP should typically match your license IP.
Is 10.10.10.5 the IP in your license? (y,n) : y
DirectAdmin will now be installed on: Enterprise 8.3
Is this correct? (must match license) (y,n) : y
Select your desired apache/php setup. Option 1 is recommended.
You can make changes from the default settings in the next step.
1: Apache 2.4, mod_ruid2, php 7.4. Can be set to use mod_php, php-FPM or fastcgi.
2: Apache 2.4, mod_ruid2, php 5.6 (php 5.6 is end-of-life)
3: Apache 2.4, mod_ruid2, php 5.6 (php 5.6 is end-of-life), MariaDB 5.5
4: Apache 2.4, php-fpm, php 7.4.
   Lưu ý: mod_ruid2 không hỗ trợ Centos 8 
Post any issues with custombuild to the forum: http://forum.directadmin.com/forumdisplay.php?f=61
Enter your choice (1, 2, 3 or 4): 4
– Cài đặt thành công sẽ hiện lên thông báo:

...
Install Complete!
If you cannot connect to the login URL, then it is likely that a firewall is blocking port 2222. Please see:
https://help.directadmin.com/item.php?id=75
– Lưu ý cần Mở port firewall

```bash
# firewall-cmd --zone=public --add-port=2222/tcp --permanent
# firewall-cmd --zone=public --add-port=21/tcp --permanent
# firewall-cmd --zone=public --add-port=80/tcp --permanent
# firewall-cmd --zone=public --add-port=25/tcp --permanent
# firewall-cmd --reload
# systemctl restart directadmin
```

Cấu hình card mạng

Lưu ý : Đối với các card mạng khác ens33 (ens18,eth0,…) cấu hình cũng tương tự.

card mang directamin nulled centOs
VD: Card mạng “ens33” mình add thêm subinterface ens33:100 để gia hạng license directadmin.

```bash
# vi /etc/sysconfig/network-scripts/ifcfg-ens33:100
DEVICE=ens33:100
IPADDR=176.99.3.34
NETMASK=255.255.255.0
```

– Thay đổi card mạng gia hạng license directadmin trong directadmin.conf

```bash
# /usr/bin/perl -pi -e 's/^ethernet_dev=.*/ethernet_dev=ens33:100/' /usr/local/directadmin/conf/directadmin.conf
```

– Tiến hành Up card mạng ens33:100

```bash
ifup ens33:100
ifup card mang directamin nulled
```

Nếu bạn không ifup được card license directadmin cần tắt arp ping để Up được card mạng này:

```bash
# vi /etc/sysconfig/network-scripts/ifup-eth
```

– Tìm dòng sau

Với Eth0:

```bash
...
if [ $? = 1 ]; then
ARPINGMAC=$(echo $ARPING | sed -ne 's/.*\[\(.*\)\].*/\1/p')
net_log $"Error, some other host ($ARPINGMAC) already uses address ${ipaddr[$idx]}."
exit 1
...
```

Với Ens18

```bash
...
if [ "${REALDEVICE}" != "lo" ] && [ "${arpcheck[$idx]}" != "no" ] ; then
/sbin/arping -q -c 2 -w 3 -D -I ${REALDEVICE} ${ipaddr[$idx]}
if [ $? = 1 ]; then
net_log $"Error, some other host already uses address ${ipaddr[$idx]}."
exit 1
```

...
Thường là dòng (279 đối với “eth0” và 257 đối với “ens18” ) “exit 1” Rem lại “# exit 1”. Rồi save lại.

Cấu hình Script gia hạn license directadmin

```bash
# vi /usr/local/directadmin/scripts/update-license.sh
```

Điền thông tin scipt vào:

```bash
#/bin/bash
# --- Điền lại tên subinterface gia hạng license nhé! --- #
/usr/sbin/ifdown ens33:100
rm -f /tmp/license.key
rm -f /usr/local/directadmin/conf/license.key
/usr/bin/wget -O /tmp/license.key.gz https://github.com/vswb/directadmin.damvt/raw/main/license.key.gz
/usr/bin/gunzip /tmp/license.key.gz
mv /tmp/license.key /usr/local/directadmin/conf/
chmod 600 /usr/local/directadmin/conf/license.key
chown diradmin:diradmin /usr/local/directadmin/conf/license.key
 # --- Điền lại tên subinterface gia hạng license nhé! --- #
/usr/sbin/ifup ens33:100
/bin/systemctl restart directadmin.service
Chạy thử Script bằng lệnh sau!

sh /usr/local/directadmin/scripts/update-license.sh
Cấu hình tự động gia hạng license:

Cấu hình tự động gia hạng license:
crontab -e
0 12 */3 * * /usr/local/directadmin/scripts/update-license.sh
– Xem thông tin đăng nhập:

cat /usr/local/directadmin/scripts/setup.txt
directadmin1 1 1
```

Màn hình đăng nhập Directadmin Nulled
cai dat directadmin nulled thanh cong
Cài đặt thành công directadmin nulled
Như vậy ta đã cài đặt thành công directadmin nulled cho centos 6,7,8