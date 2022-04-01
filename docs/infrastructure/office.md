# Office 365

## 申请方式 {#application}

理论上任何社团负责人或者在社团中负责重要项目的人员都可以申请，原则是按需分配，因为邮箱是工作工具，而不是福利资源。

同理，不再担任负责人且不再处理事务的同学使用的邮箱应该收回（见下方 [默认地址](#default-route) 一节）。

## 邮件礼仪 {#email-etiquette}

tky: 

**CC（抄送）和设置回复地址的目的都是为了让所有 LUG 负责的同学可以看到事件最新的进展**（抄送会把你发的邮件给所有的负责人；**回复地址设置之后，对方就知道这是你代表 LUG 写的邮件，并且默认回复邮件的时候地址就是所有负责人的邮件列表**），所以下文中要求设置这些内容。

如果遇到需要以私人身份，或者以其他非 LUG 代表负责人的身份回复邮件的场合，请修改回复地址信息。因为 Outlook 网页版不便于修改这些内容，建议使用邮件客户端处理。（个人推荐 ThunderBird）。

(2021/11/06 update): 对于需要向非邮件列表的不特定群体群发的邮件（例如通知类消息），请注意不要将所有邮箱都放在收件人里，否则**所有收到邮件的人都能看到其他收件人的邮箱（隐私问题）；并且收件人如果回复邮件不当，其他的收件人也会收到其回复**。一种方便的做法是：将所有需要收到通知的收件人放在**密送 (BCC)**一栏中，收件人填写原抄送地址。

我们加入了很多邮件列表，其中经常有各种往来邮件（特别是 CentOS mirror announcement 这个列表，已退），它们大多数不需要我们理会。

总之，不知道怎么处理的邮件不要贸然回复。如果你认为某一封邮件需要我们处理但不知道怎么处理，请转告给其他相关同学。

以下内容从 Hypercude 编写的内容中截取：

> 回复任何邮件时，请抄送 / CC（不是密送 / BCC）给原邮件的收件地址！（比如别人发到 lug A ustc.edu.cn ，回复时也请 CC 到 lug A ustc.edu.cn）
> 
> 请不要“只回复邮件”。如果在回复中说“我们会做某某事”，请注意除非你明确转交给了别人，这件事应当由你来完成。

## 邮件签名 {#email-signature}

Outlook 无法直接通过网页端添加发件人名称、设置回复地址，因此只能通过邮件客户端进行使用。

## Thunderbird

在登录时，输入了用户名、密码后，会显示无法找到对应的邮箱配置

![Thunderbird auto config failed](img/thunderbird-auto-conf-failed.jpg)

进行如下的手动配置：

- Incoming Server
    - Hostname: outlook.office365.com
    - Port: 993
    - Connection security: SSL/TLS
    - Authentication: Autodetect
- Outgoing server
    - Hostname: smtp.office365.com
    - Port: 587
    - Connection security: STARTTLS
    - Authentication: Autodetect

如下图：

![Thunderbird manually config](img/thunderbird-conf-manual.jpg)

然后点左下角的 `Re-test`，重新搜索到配置后，在两个 Authentication method 中均选择 OAthu2

![Thunderbird re-test](img/thunderbird-re-test.jpg)

然后点 `Done`。在弹出的窗口中完成认证。

在完成后，在右上角中选择账户设置，在默认身份中

- 修改 “您的姓名“ 为 “Zeyu Gao on behalf of USTC LUG”（请换成自己的名字）
- ”回复地址“ 修改为 “`lug@ustc.edu.cn`”
- “签名文字” 为（最后一行换成自己的信息）

```
Linux User Group
University of Science and Technology of China
Homepage: https://lug.ustc.edu.cn/
E-Mail: lug@ustc.edu.cn
Zeyu Gao (高泽豫) <zeyugao@ustclug.org>
```

结果如图：

![Thunderbird Conf](./img/thunderbird-account-settings.jpg)

### 使用 Thunderbird 配置不同的身份

(written by taoky)

在某些情况下，需要设置新的发件人名称和回复地址（例如 hackergame staff 需要一套不同的设置）。由于 Gmail 网页端修改配置很麻烦（而且很容易忘记改回来），强烈建议使用邮件客户端。个人使用的是 Thunderbird，下面也以它为例子。

在账号加上邮箱之后，点击右键 -> 属性，默认配置（LUG Staff）如图：

![Thunderbird - 1](./img/thunderbird-1.jpg)

需要添加新身份时，点击右下角「管理标识」，添加对应的标识。对于 hackergame，可以配置如下：

![Thunderbird - 2](./img/thunderbird-2.png)

配置完成后，在编写邮件时，就可以选择新的标识了，并且发件人名称、回复地址和签名都会自动设置好（抄送还是要自己设置，别忘了！）

## Outlook 客户端

使用 Outlook 客户端可以使用完整的 Outlook 功能，包括在 Web 端设置的自定义规则等。

### GMail

!!! warning

    由于 Google 将 G Suite 全面转向付费服务，我们在 2022 年 3 月 31 日后停止使用 G Suite 相关服务。转向 Office 365 提供的服务。以下内容仅作为存档与参考

以下原文由 Hypercube 编写

> 大家好，
>
> 请各位阅读下方内容，并按指示配置自己的邮箱：
>
> 登录网页版 Gmail，在右上角点开设置，于“常规”标签页中设置“签名”为纯文本如下内容（共 5 行，将最后一行换成自己的信息）：
>
> > Linux User Group  
> > University of Science and Technology of China  
> > Homepage: <https://lug.ustc.edu.cn/>  
> > E-Mail: <lug@ustc.edu.cn>  
> > Zibo Wang (王子博) &lt;<example@ustclug.org>&gt;
>
> 于“账号”标签页中“用这个地址发送邮件”内点“修改信息”，在弹出窗口中输入名称“Zibo Wang on behalf of USTC LUG”（请换成自己的名字），输入回复地址“`lug@ustc.edu.cn`”。
>
> 还可以视自己需要在“转发和 POP / IMAP”标签页中配置自动转发，但请注意，如果你配置了转发到自己的常用邮箱，请不要直接从常用邮箱回复邮件，而应该登录 LUG 邮箱回复。
> 回复任何邮件时，请抄送 / CC（不是密送 / BCC）给原邮件的收件地址！（比如别人发到 lug A ustc.edu.cn ，回复时也请 CC 到 lug A ustc.edu.cn）
> 
> 请不要“只回复邮件”。如果在回复中说“我们会做某某事”，请注意除非你明确转交给了别人，这件事应当由你来完成。

在添加了签名后，在下面的“默认签名设置”中，将“用于新电子邮件”以及“用于回复/转发”均选择为上面添加的签名。

记得滚动到页面最下方点击“保存页面”！

## 加入 lug @ ustc 列表 {#lug-ustc-mailing-list}

若要收到发往 lug A ustc.edu.cn 的邮件，需要在 [群组管理](https://admin.google.com/ac/groups) 这里将用户加入 USTC LUG Staff 组。这个群组就是 lug 和 mirrors 在学校邮箱设置的转发目标。

## 设置默认地址 {#default-route}

G Suite 支持将单个地址设为“默认地址”，用于接受发往不存在的地址的邮件。

参考资料：<https://support.google.com/a/answer/2368153>

对于中文界面，应该从 Google Admin 控制台按顺序选择 **应用** → **G Suite** → **Gmail** → **高级设置**，其中的 **无限别名地址** 就是这个选项，一般发给会长或 CTO。
