// XDVDFS reader and importer. Format references: ISO_IMPORT.md.
using System;
using System.IO;
using System.Text;
using System.Collections.Generic;
using System.Security.Cryptography;

namespace MajinDisc {
 public sealed class Info {
  public string TitleId, MediaId, Version, RegionMask, Regions, Sha256;
  public bool Supported;
  public long Bytes;
  public int Files;
 }
 public sealed class Image : IDisposable {
  sealed class Entry { public string Path; public long Offset; public int Size; }
  FileStream stream;
  long partition;
  List<Entry> files = new List<Entry>();
  HashSet<string> paths = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
  HashSet<long> directories = new HashSet<long>();
  long directoryBytes;
  public Info Details { get; private set; }
  const string Expected = "660CAE389F0A45100739F935472437D282B2568FCFC2C60FC5A9B2B7B48CE1EC";
  public Image(string path) {
   try {
    stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read);
    byte[] descriptor = null;
    foreach(long candidate in new long[]{0,0xFB20,0x20600,0x2080000,0xFD90000,0x18300000}) {
     long position = candidate + 65536;
     if(position + 2048 > stream.Length) continue;
     byte[] d = Read(position,2048);
     if(Encoding.ASCII.GetString(d,0,20)=="MICROSOFT*XBOX*MEDIA" && Encoding.ASCII.GetString(d,2028,20)=="MICROSOFT*XBOX*MEDIA") {
      if(descriptor!=null) throw new InvalidDataException("Ambiguous game partitions.");
      descriptor=d; partition=candidate;
     }
    }
    if(descriptor==null) throw new InvalidDataException("No supported Xbox disc filesystem found. Choose an uncompressed Xbox 360 ISO or an extracted game folder. PS3, archives and split images are not supported.");
    Walk(BitConverter.ToUInt32(descriptor,20),BitConverter.ToUInt32(descriptor,24),"",0);
    Entry executable=files.Find(e=>e.Path.Equals("default.xex",StringComparison.OrdinalIgnoreCase));
    if(executable==null) throw new InvalidDataException("This image has no Xbox 360 default.xex.");
    if(executable.Size>64*1024*1024) throw new InvalidDataException("Executable exceeds inspection limit.");
    Details=InspectXex(Read(executable.Offset,executable.Size));
    Details.Files=files.Count;
    bool kb=false,system=false;
    foreach(Entry e in files) {
     Details.Bytes+=e.Size;
     if(Details.Bytes>16L*1024*1024*1024) throw new InvalidDataException("Disc extraction exceeds the 16 GiB safety limit.");
     if(e.Size>0 && e.Path.StartsWith("finalizedXBox360/KB/",StringComparison.OrdinalIgnoreCase)) kb=true;
     if(e.Size>0 && e.Path.StartsWith("finalizedXBox360/system/",StringComparison.OrdinalIgnoreCase)) system=true;
    }
    if(Details.Supported && (!kb || !system)) throw new InvalidDataException("Required game-data folders are missing or empty.");
   } catch {Dispose(); throw;}
  }
  byte[] Read(long offset,int count) {
   if(offset<0 || count<0 || offset>stream.Length-count) throw new InvalidDataException("Truncated or invalid disc image.");
   byte[] data=new byte[count]; stream.Position=offset;
   int done=0; while(done<count) {int n=stream.Read(data,done,count-done); if(n==0) throw new EndOfStreamException(); done+=n;}
   return data;
  }
  void Walk(uint sector,uint size,string parent,int depth) {
   if(depth>32 || size>32*1024*1024 || (directoryBytes+=size)>128*1024*1024 || !directories.Add(sector)) throw new InvalidDataException("Invalid directory structure.");
   if(size==0) return;
   byte[] table=Read(partition+(long)sector*2048,(int)size);
   Stack<int> pending=new Stack<int>(); pending.Push(0);
   HashSet<int> visited=new HashSet<int>();
   while(pending.Count>0) {
    int p=pending.Pop();
    if(!visited.Add(p) || p<0 || p>table.Length-14) throw new InvalidDataException("Invalid directory entry.");
    int n=table[p+13]; if(n==0 || p+14+n>table.Length) throw new InvalidDataException("Invalid filename.");
    for(int i=0;i<n;i++) if(table[p+14+i]<32 || table[p+14+i]>126) throw new InvalidDataException("Unsupported filename encoding.");
    string name=Encoding.ASCII.GetString(table,p+14,n);
    string stem=name.Split('.')[0].TrimEnd(' ').ToUpperInvariant();
    if(name=="." || name==".." || name.EndsWith(".") || name.EndsWith(" ") || name.IndexOfAny(new char[]{'/', '\\', ':','*','?','"','<','>','|'})>=0 || stem=="CON" || stem=="PRN" || stem=="AUX" || stem=="NUL" || System.Text.RegularExpressions.Regex.IsMatch(stem,@"^(COM|LPT)[0-9]$")) throw new InvalidDataException("Unsafe filename in image.");
    string relative=parent+name;
    if(relative.Length>200 || !paths.Add(relative) || paths.Count>100000) throw new InvalidDataException("Duplicate or excessive paths.");
    uint start=BitConverter.ToUInt32(table,p+4), length=BitConverter.ToUInt32(table,p+8);
    long offset=partition+(long)start*2048;
    if(offset>stream.Length-length || length>int.MaxValue) throw new InvalidDataException("File extends outside image.");
    foreach(int child in new int[]{BitConverter.ToUInt16(table,p),BitConverter.ToUInt16(table,p+2)}) if(child!=0) pending.Push(child*4);
    if((table[p+12]&16)!=0) Walk(start,length,relative+"/",depth+1);
    else files.Add(new Entry{Path=relative,Offset=offset,Size=(int)length});
   }
  }
  static uint Big(byte[] b,int p) {
   if(p<0 || p>b.Length-4) throw new InvalidDataException("Truncated XEX header.");
   return ((uint)b[p]<<24)|((uint)b[p+1]<<16)|((uint)b[p+2]<<8)|b[p+3];
  }
  public static Info InspectXex(byte[] data) {
   if(data.Length<24 || Encoding.ASCII.GetString(data,0,4)!="XEX2") throw new InvalidDataException("Not an Xbox 360 XEX2 executable.");
   uint count=Big(data,20); if(count>4096) throw new InvalidDataException("Invalid XEX headers.");
   int execution=-1;
   for(int i=0;i<count;i++) if(Big(data,24+i*8)==0x40006) execution=checked((int)Big(data,28+i*8));
   if(execution<0) throw new InvalidDataException("Missing execution identity.");
   uint region=Big(data,checked((int)Big(data,16)+0x178));
   uint version=Big(data,execution+4);
   string hash; using(SHA256 sha=SHA256.Create()) hash=BitConverter.ToString(sha.ComputeHash(data)).Replace("-","");
   List<string> regions=new List<string>();
   if((region&0xFF)!=0) regions.Add("NTSC-U (Americas)");
   if((region&0x100)!=0) regions.Add("Japan");
   if((region&0xFE00)!=0) regions.Add("Other NTSC-J territories");
   if((region&0xFF0000)!=0) regions.Add("PAL territories");
   if((region&0xFF000000)!=0 && region!=uint.MaxValue) regions.Add("Other region bits");
   return new Info {TitleId=Big(data,execution+12).ToString("X8"),MediaId=Big(data,execution).ToString("X8"),Version=String.Format("{0}.{1}.{2}.{3}",version>>28,(version>>24)&15,(version>>8)&65535,version&255),RegionMask=region.ToString("X8"),Regions=region==uint.MaxValue?"Region-free":(regions.Count==0?"Unspecified":String.Join(", ",regions.ToArray())),Sha256=hash,Supported=hash==Expected && Big(data,execution+12)==0x4E4D0816};
  }
  // Import only into a new directory; incomplete imports are never selected.
  public void Extract(string destination,Action<int> progress) {
   if(!Details.Supported) throw new InvalidDataException("This game/revision is not supported. No files were imported.");
   string root=Path.GetFullPath(destination);
   if(Directory.Exists(root) || File.Exists(root)) throw new IOException("Import destination already exists.");
   Directory.CreateDirectory(root);
   byte[] buffer=new byte[1024*1024]; long done=0; int previous=-1;
   foreach(Entry e in files) {
    string output=Path.GetFullPath(Path.Combine(root,e.Path.Replace('/',Path.DirectorySeparatorChar)));
    if(!output.StartsWith(root+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase)) throw new InvalidDataException("Invalid output path.");
    Directory.CreateDirectory(Path.GetDirectoryName(output));
    stream.Position=e.Offset;
    using(FileStream target=new FileStream(output,FileMode.CreateNew,FileAccess.Write,FileShare.None)) {
     int left=e.Size;
     while(left>0) {int n=stream.Read(buffer,0,Math.Min(left,buffer.Length)); if(n==0) throw new EndOfStreamException(); target.Write(buffer,0,n); left-=n; done+=n;}
    }
    int percent=(int)(done*100/Math.Max(1,Details.Bytes));
    if(percent!=previous && progress!=null) {progress(percent);previous=percent;}
   }
  }
  public void Dispose() {if(stream!=null) {stream.Dispose();stream=null;}}
 }
}
