# IRIS Labs Hardware Recruitments - Assignment 1

## Part A : Testing CDC understanding
Questions:
1. Explain why synchronizing each bit of an encoded multi-bit control signal independently can lead to incorrect decoding in the receiving clock domain.

 The main problem with using individual synchronizers for multi-bit signal is the fact that the different flip flops that sample these bits may not do it at the exact same point .This can be due to slightly different electronic features internal to the different flip flops due to factors such as process variations across their die or due to possible external factors such as small data changing skews or slighly different propagation delay for the flip flops .Also, another issue is that the different synchronizers can have different metastability resolution times as well as possibly different rise and fall times. These differences can cause different bits to not reach the destination simultaneously and can get sampled at different at different clock edge in the destination clock edges. As a result, this can cause unwanted or wrong intermediate output signals to form at the destination.

2. Using the timing diagram, describe how skew between b[1] and b[0] causes adec[2:0] to momentarily take an invalid intermediate value.
 
 In the given timing diagram(in waveform.png file), it can be seen that b[0] transition at a slightly prior moment to b[1] and b[2]. Due to this reason, aq1[0] transitions to logic 1 ,one clock cycle(of Aclk) before aq1[1] and aq1[2] are asserted to logic 1 .Due to this, an unintended intermediate aq signal of 001 is asserted causing an invalid intermediate decode signal of aen[1] to be set for one cycle period before aq1 becomes 111 leading to the correct intended decode signal of aen[7] to be set.

3. Identify the fundamental CDC design mistake illustrated in this figure.

 The fundamental CDC mistake in the given design is not taking into the account the importance of synchronization of multi-bit signals in the receiving clock domain. The design overlooks the differences that can arise when multiple bits in a signal are passed to a different clock domain each with their own individual synchronizers. The slight differences that can arise in this setup(due to factors given in Q1) can cause data incoherency as illegal or unintended intermediate signals are formed at the destination. It is important that only one bit signals or properly encoded signals(such as gray code where multiple bits do not change in transition) are passed through synchronizers.

4. Propose three different design techniques that can be used to safely transfer this control information across clock domains without generating spurious decoded outputs.

 Three techniques that can be used to safely transfer this multi bit control information across clock domains without generating spurious decoded outputs are as follows:
### 1.Mux recirculation :  
A one bit control signal is synchronized to receiving clock domain using a valid single bit synchronization technique such as 2-flip flop synchronizer or toggle synchronizer. When the control signal is asserted the multi bit data signal is made stable and unchanging , the control signal is then synchronized to receiving clock domain after which point all the bits in the multi bit signal is sampled simultaneously .A mux is present in destination which selects the new data when the control bit is toggled ,else it keeps the previous data. The designer has to make sure that the multi bit data is not modified during the time period between the control bit being asserted and sent to the destination clock domain until the entire data is captured at receiving clock.Hence, this technique is useful when data is not changing frequently in source domain. 

### 2.Handshake protocol :
An improvement over the single bit control technique used in previous point is the use of valid/acknowledge handshaking signals which can  make the setup more robust. The source flip flop launches the valid control signal bit which is synchronized to receiving clock domain using a single bit synchronizer such as a 2-flip flop synchronizer .When valid is detected , the receiving clock starts the sampling the stable multi bit data. After the sampling ,the domain sends back acknowledge signal back to source .This process can be repeated to ensure safe exchange of data .

### 3.Asynchronous FIFO :
An asynchronous FIFO consists of a small shared memory where data from source is stored. It uses a read and write pointer to read from this memory by destination and write to this memory by source domain respectively.The pointers are incremented as to when data is read from or written to FIFO. The key idea is that the data doesn't cross the clock domains, only the pointers do. There is a mechanism to check whether the FIFO is full or empty. The destination should not read from the FIFO when it is empty and the source should not write to it when it is full. Another important consideration here is how the two pointers are implemented .Since they will be have to pass through the clock domain, using binary encoding for this can cause problems as multi bit binary transitions can cause more than one bit to change in transition ,hence , we are back to the problem of synchronizing multi bit values across the two clocks. The solution to this is to use gray code encoding for pointers .When a gray code value is incremented , only a single bit change happens in it. Hence, this becomes a single bit synchronization problem which can solved using any of our single bit synchronization techniques. 

## Part B : Designing data-processing block
### Design of processing block:
Initially , I have Implemented data processing logic in data_proc.v file before dealing with the clock domain synchronization of data producing and data processing blocks. The features of the block :
- Streaming valid/ready interface: A minimal two-way handshake protocol between the data-producing block and data-processing block as well as between the data processing block and any dependent block/consumer that may want to accept the processed data from this domain. It uses standard READY/VALID signals to establish data transfer.
- The data processing block supports all three required processing modes : bypass, invert and convolution. In bypass mode, the pixel inputs are sent to output as it is without any processing done on it while in invert mode, each of the pixel values are inverted . For convolution , i have taken a simple  3x3 box blur kernel(each of the 9 matrix elements are 1) which basically takes a pixel and it's neighbouring pixel values and takes their average ,giving blurry effect.
- Line buffer architecture is used to store pixels for convolution to increase memory usage efficiency .At a time, only threes of 32 pixels(96 bytes) are used ,only enough pixels to apply convolution for a single pixel .This improves memory usage as the entire 32x32 image don't have to be stored in memory all at once.
- Reset control signal along with proper reset behaviour for all the signals are implemented .

### CDC handling:
Since the producing and processing clocks are in different clock domains, synchronization is needed to resolve the pixel data loss from producer to processor . Asynchronous fifo with gray coded pointers are chosen for this purpose .The gray coded pointers are synchronized across the two domains using a 2 flip flop synchronizer .The FIFO acts as the interface between the producing block and processing block ,keeping track of pixels coming in from producer and storing them in buffer and later letting the processing block access it. This is important since the producer is running on a faster clock than processing module, and as such there would be data loss from producer to processor if there was not a FIFO buffer to store the pixels coming in at a faster rate and giving enough time to the processing module to access the pixel values in it's clock domain.

### Testbench validation: 
For validating the testbench , i've used a sample checkerboard 32x32 image(original_checkerboard.jpg) in it's hex format(image.hex). The testbench is updated with required signals and instantiations .All the 3 modes are tested and for the fourth mode value(1'b11) ,a display message is produced to show that no valid outputs are produced here. For the three valid modes, a separate hex value is given as output after the required operations are done on the pixels: output_bypass.hex,output_invert.hex and output_conv.hex. A python script(hex_to_image) is used to convert these output hex files and the original hex file back to jpg format so that final results can be validated .

<table style="width:100%">
  <tr>
    <td align="center" style="width:20%">
      <img src="./data_prod_proc/Original_checkerboard.jpg" width="75%" />
      <br />
      <b>Original</b>
    </td>
    <td align="center" style="width:20%">
      <img src="./data_prod_proc/bypass_checkerboard.jpg" width="75%" />
      <br />
      <b>Bypass</b>
    </td>
    <td align="center" style="width:20%">
      <img src="./data_prod_proc/invert_checkerboard.jpg" width="75%" />
      <br />
      <b>Inverted</b>
    </td>
    <td align="center" style="width:20%">
      <img src="./data_prod_proc/conv_checkerboard.jpg" width="75%" />
      <br />
      <b>Convoluted</b>
    </td>
  </tr>
</table>

