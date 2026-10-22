"""Loopback-only SSH fixture: no real board access and no shell execution."""
import argparse,json,select,socket,threading
from pathlib import Path
import paramiko
class Fixture:
 def __init__(self):
  self.key=paramiko.RSAKey.generate(2048);self.listener=socket.socket();self.listener.bind(('127.0.0.1',0));self.listener.listen(16);self.port=self.listener.getsockname()[1]
  threading.Thread(target=self.accept,daemon=True).start()
 def accept(self):
  while True:
   client,_=self.listener.accept();threading.Thread(target=self.serve,args=(client,),daemon=True).start()
 def serve(self,client):
  t=paramiko.Transport(client);t.add_server_key(self.key);destinations={}
  class Server(paramiko.ServerInterface):
   def get_allowed_auths(self,username):return 'password'
   def check_auth_password(self,username,password):return paramiko.AUTH_SUCCESSFUL if username=='dev' and password=='dev' else paramiko.AUTH_FAILED
   def check_channel_pty_request(self,*args):return True
   def check_channel_request(self,kind,chanid):return paramiko.OPEN_SUCCEEDED if kind=='session' else paramiko.OPEN_FAILED_ADMINISTRATIVELY_PROHIBITED
   def check_channel_direct_tcpip_request(self,chanid,origin,destination):
    if destination==('127.0.0.1',algorithm.port):destinations[chanid]=destination;return paramiko.OPEN_SUCCEEDED
    return paramiko.OPEN_FAILED_ADMINISTRATIVELY_PROHIBITED
   def check_channel_exec_request(self,channel,command):
    def respond():
     if command==b'nexus-test-auth':out=b'NEXUS_SSH_AUTH_OK\n';rc=0
     elif command==b"printf '%s\\n' dev | sudo -S -p '' cat /etc/uav-record-api/token":out=b'a'*64+b'\n';rc=0
     else:out=b'Rejected by isolated fixture\n';rc=127
     channel.sendall(out);channel.send_exit_status(rc);channel.shutdown_write();channel.close()
    threading.Timer(0.05,respond).start();return True
  try:
   t.start_server(server=Server())
   while t.is_active():
    ch=t.accept(1)
    if ch is not None and ch.get_id() in destinations:threading.Thread(target=self.forward,args=(ch,destinations[ch.get_id()]),daemon=True).start()
  except (EOFError,OSError,paramiko.SSHException):pass
  finally:t.close()
 def forward(self,ch,dest):
  try:
   with socket.create_connection(dest,timeout=5) as upstream:
    while True:
     ready,_,_=select.select([ch,upstream],[],[],15)
     if not ready:return
     for src in ready:
      data=src.recv(65536)
      if not data:return
      (upstream if src is ch else ch).sendall(data)
  except (OSError,EOFError):pass
  finally:ch.close()
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--output',required=True);a=p.parse_args()
 algorithm=Fixture();main=Fixture();Path(a.output).write_text(json.dumps({'main_port':main.port,'algorithm_port':algorithm.port}));threading.Event().wait()
