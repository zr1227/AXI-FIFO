该项目为AXI-Lite接口的异步FIFO，支持输入数据位宽为输出位宽的2倍，1倍，0.5倍和1/3倍的模式。下面将介绍具体的输入输出信号以及相关事项。
输入信号：
  din，输入数据。
  i_clk,输入数据时钟。
  o_clk,输出数据时钟。
  i_tlast，输入数据流结束标志位。
  i_vaild,输入数据有效标志位，
  i_tready,fifo准备好接受数据标志位。
输出信号：
  dout，输出数据。
  o_tlast,输出数据流结束标记位。
  o_vaild,输出数据有效标志位。
  o_tready，从设备准备好接受数据标志位。
当o_tready和内部memory寄存器组未满时，i_tready有效表示可以接受数据。当i_vaild为高时，表示数入数据有效，输入数据被写入进内部memory中，此时memory非空，状态机开始工作进行读取数据。当memory为空时，状态机停止读数并等待memory非空，当memory被写满时，i_tready拉低并停止接受数据知道该信号在此拉高。
