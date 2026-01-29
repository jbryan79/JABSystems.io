using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using JABDriveHygieneGUI.Models;

namespace JABDriveHygieneGUI.Services
{
    public class PowerShellService
    {
        private readonly string _scriptPath;

        public PowerShellService()
        {
            // Script should be in the same directory as the executable
            var appDir = AppDomain.CurrentDomain.BaseDirectory;
            _scriptPath = Path.Combine(appDir, "JAB-DriveHygieneCheck.ps1");

            if (!File.Exists(_scriptPath))
            {
                throw new FileNotFoundException($"PowerShell script not found at: {_scriptPath}");
            }
        }

        public async Task<ScanResult> RunInspectionAsync()
        {
            var startInfo = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = $"-ExecutionPolicy Bypass -NoProfile -File \"{_scriptPath}\" -JsonOutput",
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true,
                StandardOutputEncoding = Encoding.UTF8,
                StandardErrorEncoding = Encoding.UTF8
            };

            using var process = new Process { StartInfo = startInfo };
            var output = new StringBuilder();
            var errors = new StringBuilder();

            process.OutputDataReceived += (sender, e) =>
            {
                if (!string.IsNullOrEmpty(e.Data))
                {
                    output.AppendLine(e.Data);
                }
            };

            process.ErrorDataReceived += (sender, e) =>
            {
                if (!string.IsNullOrEmpty(e.Data))
                {
                    errors.AppendLine(e.Data);
                }
            };

            process.Start();
            process.BeginOutputReadLine();
            process.BeginErrorReadLine();

            await process.WaitForExitAsync();

            if (process.ExitCode != 0)
            {
                throw new Exception($"PowerShell script failed with exit code {process.ExitCode}. Errors: {errors}");
            }

            var jsonOutput = output.ToString();
            if (string.IsNullOrWhiteSpace(jsonOutput))
            {
                throw new Exception("No output received from PowerShell script");
            }

            try
            {
                var result = JsonSerializer.Deserialize<ScanResult>(jsonOutput);
                if (result == null)
                {
                    throw new Exception("Failed to deserialize JSON output");
                }
                return result;
            }
            catch (JsonException ex)
            {
                throw new Exception($"Failed to parse JSON output: {ex.Message}\nOutput: {jsonOutput}");
            }
        }

        public async Task<string> ExportReportAsync(string format, string outputPath)
        {
            var formatArg = format.ToUpper() == "HTML" ? "HTML" : "Text";

            var startInfo = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = $"-ExecutionPolicy Bypass -NoProfile -File \"{_scriptPath}\" -ExportReport -ReportFormat {formatArg} -OutputPath \"{outputPath}\"",
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true,
                StandardOutputEncoding = Encoding.UTF8
            };

            using var process = new Process { StartInfo = startInfo };
            var output = new StringBuilder();

            process.OutputDataReceived += (sender, e) =>
            {
                if (!string.IsNullOrEmpty(e.Data))
                {
                    output.AppendLine(e.Data);
                }
            };

            process.Start();
            process.BeginOutputReadLine();
            await process.WaitForExitAsync();

            // Parse output to find the report path
            var outputText = output.ToString();
            var lines = outputText.Split('\n');
            foreach (var line in lines)
            {
                if (line.Contains("DriveHygieneCheck_") && (line.Contains(".html") || line.Contains(".txt")))
                {
                    // Extract the file path
                    var trimmedLine = line.Trim();
                    if (File.Exists(trimmedLine))
                    {
                        return trimmedLine;
                    }
                }
            }

            throw new Exception("Failed to locate exported report file");
        }

        public void LaunchDiskCleanup(string driveLetter = "C")
        {
            try
            {
                Process.Start(new ProcessStartInfo
                {
                    FileName = "cleanmgr.exe",
                    Arguments = $"/D {driveLetter}",
                    UseShellExecute = true
                });
            }
            catch (Exception ex)
            {
                throw new Exception($"Failed to launch Disk Cleanup: {ex.Message}");
            }
        }

        public void OpenScriptFile()
        {
            try
            {
                Process.Start(new ProcessStartInfo
                {
                    FileName = _scriptPath,
                    UseShellExecute = true
                });
            }
            catch (Exception ex)
            {
                throw new Exception($"Failed to open script file: {ex.Message}");
            }
        }
    }
}
