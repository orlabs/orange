#### Systemtap Flame Graph

First, you can install `systemtap`,[FlameGraph tools](https://github.com/brendangregg/FlameGraph) and `wrk` by yourself or refer `https://github.com/noname007/script/tree/master/systemtap` to install.

Second, run the cmd and wait a miniute at the project root dir.

    make -f development.mk URL=YOUR_BENCH_URL systemtap

`YOUR_BENCH_URL`: please replace it with your url
