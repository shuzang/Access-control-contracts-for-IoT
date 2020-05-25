

系统中共有三种合约：管理合约（Management Contract, MC），访问控制合约（Access Control Contract, ACC），信誉合约（Reputation Contract, RC），相互间的调用关系如下图

![合约架构](F:\static\images\README\合约架构.png)

管理合约（Management Contract, MC），负责管理合约和设备属性。在设备属性中新增TimeofUnblock 字段，用于设置阻塞终止时间，该字段只能被信誉合约更新。MC中各种操作行为会产生日志并提交给信誉合约

访问控制合约（Access Control Contract，ACC），负责管理资源属性、策略和执行访问控制。在执行访问控制判断时，会首先从 MC 读取 TimeofUnblock 字段，查看是否大于当前时间，如果大于则阻塞请求，否则通过。同样，ACC 中的所有行为记录也会提交到 RC

信誉合约（Reputation Contract, RC），负责根据 MC 和 ACC 提交的记录计算信誉函数的值，并根据该值计算阻塞终止时间，最后调用 MC 的相关函数更新设备的 TimeofUnblock 字段。



