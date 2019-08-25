<Query Kind="Program">
  <Reference>&lt;RuntimeDirectory&gt;\System.IO.Compression.dll</Reference>
  <Reference>&lt;RuntimeDirectory&gt;\System.IO.Compression.ZipFile.dll</Reference>
  <Reference>&lt;RuntimeDirectory&gt;\System.IO.Compression.FileSystem.dll</Reference>
  <NuGetReference>Newtonsoft.Json</NuGetReference>
  <Namespace>Newtonsoft.Json</Namespace>
  <Namespace>System.IO.Compression</Namespace>
</Query>

string path = @"D:\Work Files\SamTrain\";

void Main()
{
	string src = Path.Combine(path, "src");
	string infoPath = Path.Combine(src, "info.json");
	
	string infoJson = File.ReadAllText(infoPath);
	var info = JsonConvert.DeserializeObject<Info>(infoJson);

	string outputFilename = $"{info.Name}_{info.Version}";
	using (var fs = new FileStream(Path.Combine(path, outputFilename + ".zip"), FileMode.OpenOrCreate, FileAccess.Write))
	using ( var zip = new ZipArchive(fs, ZipArchiveMode.Create))
	{
		//var entry = zip.CreateEntry(outputFilename + "/");
		
		var srcFiles = Directory.GetFiles(src, "*", SearchOption.AllDirectories);
		foreach(var srcFile in srcFiles) 
		{
			string relativePath = srcFile.Substring(src.Length).TrimStart('\\');
			string outSrcFile = Path.Combine($@"{outputFilename}\", relativePath.Replace('\\', '/'));
			zip.CreateEntryFromFile(srcFile, outSrcFile);
		}
	}
}

// Define other methods and classes here
public class Info {
	public string Name { get; set; }
	public string Version { get; set; }
	public string Title { get; set; }
	public string Author { get; set; }
	public string Contact { get; set; }
	public string Homepage { get; set; }
	public string Description { get; set; }
	[JsonProperty("factorio_version")]
	public string FactorioVersion { get; set; }
	public string[] Dependencies { get; set; }
}

class MyEncoder : UTF8Encoding
{
	public MyEncoder()
	{

	}
	public override byte[] GetBytes(string s)
	{
		s = s.Replace("\\", "/");
		return base.GetBytes(s);
	}
}