using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace JABDriveHygieneGUI.Models
{
    public class ScanResult
    {
        [JsonPropertyName("Metadata")]
        public Metadata? Metadata { get; set; }

        [JsonPropertyName("PhysicalDisks")]
        public List<PhysicalDisk>? PhysicalDisks { get; set; }

        [JsonPropertyName("SmartData")]
        public List<SmartData>? SmartData { get; set; }

        [JsonPropertyName("Volumes")]
        public List<Volume>? Volumes { get; set; }

        [JsonPropertyName("TrimInfo")]
        public TrimInfo? TrimInfo { get; set; }

        [JsonPropertyName("UsageBreakdown")]
        public List<UsageItem>? UsageBreakdown { get; set; }

        [JsonPropertyName("Summary")]
        public Summary? Summary { get; set; }
    }

    public class Metadata
    {
        [JsonPropertyName("Version")]
        public string? Version { get; set; }

        [JsonPropertyName("Timestamp")]
        public DateTime Timestamp { get; set; }

        [JsonPropertyName("IsAdministrator")]
        public bool IsAdministrator { get; set; }

        [JsonPropertyName("ComputerName")]
        public string? ComputerName { get; set; }
    }

    public class PhysicalDisk
    {
        [JsonPropertyName("DeviceId")]
        public int DeviceId { get; set; }

        [JsonPropertyName("FriendlyName")]
        public string? FriendlyName { get; set; }

        [JsonPropertyName("MediaType")]
        public string? MediaType { get; set; }

        [JsonPropertyName("BusType")]
        public string? BusType { get; set; }

        [JsonPropertyName("HealthStatus")]
        public string? HealthStatus { get; set; }

        [JsonPropertyName("OperationalStatus")]
        public string? OperationalStatus { get; set; }

        [JsonPropertyName("Size")]
        public long Size { get; set; }

        [JsonPropertyName("SizeFormatted")]
        public string? SizeFormatted { get; set; }
    }

    public class SmartData
    {
        [JsonPropertyName("DiskId")]
        public int DiskId { get; set; }

        [JsonPropertyName("FriendlyName")]
        public string? FriendlyName { get; set; }

        [JsonPropertyName("HealthStatus")]
        public string? HealthStatus { get; set; }

        [JsonPropertyName("OperationalStatus")]
        public string? OperationalStatus { get; set; }

        [JsonPropertyName("Temperature")]
        public string? Temperature { get; set; }

        [JsonPropertyName("ReadErrors")]
        public object? ReadErrors { get; set; }

        [JsonPropertyName("WriteErrors")]
        public object? WriteErrors { get; set; }

        [JsonPropertyName("PowerOnHours")]
        public object? PowerOnHours { get; set; }

        [JsonPropertyName("Wear")]
        public string? Wear { get; set; }
    }

    public class Volume
    {
        [JsonPropertyName("DriveLetter")]
        public string? DriveLetter { get; set; }

        [JsonPropertyName("VolumeName")]
        public string? VolumeName { get; set; }

        [JsonPropertyName("FileSystem")]
        public string? FileSystem { get; set; }

        [JsonPropertyName("TotalSize")]
        public long TotalSize { get; set; }

        [JsonPropertyName("TotalSizeFormatted")]
        public string? TotalSizeFormatted { get; set; }

        [JsonPropertyName("FreeSpace")]
        public long FreeSpace { get; set; }

        [JsonPropertyName("FreeSpaceFormatted")]
        public string? FreeSpaceFormatted { get; set; }

        [JsonPropertyName("UsedSpace")]
        public long UsedSpace { get; set; }

        [JsonPropertyName("UsedSpaceFormatted")]
        public string? UsedSpaceFormatted { get; set; }

        [JsonPropertyName("PercentUsed")]
        public double PercentUsed { get; set; }

        [JsonPropertyName("PercentFree")]
        public double PercentFree { get; set; }

        [JsonPropertyName("Status")]
        public string? Status { get; set; }
    }

    public class TrimInfo
    {
        [JsonPropertyName("TrimEnabled")]
        public bool TrimEnabled { get; set; }

        [JsonPropertyName("RawOutput")]
        public string? RawOutput { get; set; }

        [JsonPropertyName("Details")]
        public string? Details { get; set; }
    }

    public class UsageItem
    {
        [JsonPropertyName("Category")]
        public string? Category { get; set; }

        [JsonPropertyName("Path")]
        public string? Path { get; set; }

        [JsonPropertyName("Size")]
        public long Size { get; set; }

        [JsonPropertyName("SizeFormatted")]
        public string? SizeFormatted { get; set; }

        [JsonPropertyName("FileCount")]
        public int FileCount { get; set; }
    }

    public class Summary
    {
        [JsonPropertyName("TotalPhysicalDisks")]
        public int TotalPhysicalDisks { get; set; }

        [JsonPropertyName("TotalVolumes")]
        public int TotalVolumes { get; set; }

        [JsonPropertyName("TotalReclaimableBytes")]
        public long TotalReclaimableBytes { get; set; }

        [JsonPropertyName("TotalReclaimableFormatted")]
        public string? TotalReclaimableFormatted { get; set; }

        [JsonPropertyName("CriticalVolumes")]
        public int CriticalVolumes { get; set; }

        [JsonPropertyName("WarningVolumes")]
        public int WarningVolumes { get; set; }
    }
}
