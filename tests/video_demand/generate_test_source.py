"""Compile production method bodies with fake QGC dependencies/receiver.
Tests manager lifecycle logic, not GStreamer transport or the full UI.
"""
from pathlib import Path
import re
here=Path(__file__).resolve().parent
root=here.parents[1]
source=(root/'src/VideoManager/VideoManager.cc').read_text()
methods=['requestedStreamMask','_loadRequestedStreams','_saveRequestedStreams','setVideoStreamVisible','_receiverWanted','_syncReceiver','_handleStartComplete','_handleStopComplete','startVideo','stopVideo','startVideoStream','stopVideoStream','_startReceiver','_stopReceiver','_restartVideo','_initVideoSink']
result=[]
for name in methods:
 m=re.search(r'(?:void|bool|int)\s+VideoManager::'+name+r'\([^)]*\)(?: const)?\s*\{',source)
 assert m,name
 pos=m.end();depth=1
 while depth:
  if source[pos]=='{':depth+=1
  if source[pos]=='}':depth-=1
  pos+=1
 result.append(source[m.start():pos])
(here/'actual_methods.inc').write_text('\n\n'.join(result))
print('Extracted',len(result),'actual production method bodies.')
