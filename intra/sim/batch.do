set streams [list\
BasketballDrill_intra_main_qp37.265 \
BasketballDrillText_intra_main_qp37.265 \
]


vlog +define+FODIR="./" ../../top/tb/*.v
vsim -quiet work.test_intra_pred_dec

foreach mystream $streams {
  
  vlog +define+FODIR="./" +define+BATCH ../tb/*.v
  restart -f -nolog
  bash -c "rm -f *.txt"
  ../../hm/HM-13.0/bin/TAppDecoderStatic -b /opt/streams/HEVC/intra_main/$mystream
  onbreak resume
  
  echo \n\n$mystream\n
  echo Luma\n
  run -a
  
  vlog +define+FODIR="./" +define+BATCH +define+INTRA_CHROMA ../tb/*.v
  restart -f -nolog
  onbreak resume
  
  echo \n\n$mystream\n
  echo Luma\n
  run -a
}

exit
