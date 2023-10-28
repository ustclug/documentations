# IPMI

## Mirrors4

这台机器的 IPMI 有 HTML5 KVM，可以直接网页使用，比较方便。

## Mirrors2/3

登录 IPMI 后，为了使用远程 Shell，需要运行一个 jnlp 文件。
此文件下载时会被 Chrome 拦截，需要额外允许一下。

此 jnlp 文件需要 Oracle JDK 7 运行，OpenJDK 7 无法运行。
指令用 `javaws a.jnlp` 即可。

Java 8 及之前 Java 的各个工具是打包在 JDK 中的，包括 Java Web Starter，即我们用的 `javaws`。
所以只需要安装 Oracle JDK 7 即可，无需安装其他的、针对 Java 9 及之后版本的其他工具。
