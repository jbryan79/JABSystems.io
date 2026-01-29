using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using JABDriveHygieneGUI.Models;
using JABDriveHygieneGUI.Services;
using Microsoft.Win32;

namespace JABDriveHygieneGUI
{
    public partial class MainWindow : Window
    {
        private readonly PowerShellService _powerShellService;
        private ScanResult? _lastScanResult;
        private DateTime? _lastScanTime;
        private TimeSpan? _lastScanDuration;

        public MainWindow()
        {
            InitializeComponent();
            _powerShellService = new PowerShellService();
            ExportPathTextBox.Text = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);
        }

        #region Navigation

        private void NavigateToInspect(object sender, RoutedEventArgs e)
        {
            ShowView(InspectView);
            UpdateNavigationSelection(sender as Button);
        }

        private void NavigateToResults(object sender, RoutedEventArgs e)
        {
            ShowView(ResultsView);
            UpdateNavigationSelection(sender as Button);
        }

        private void NavigateToExport(object sender, RoutedEventArgs e)
        {
            ShowView(ExportView);
            UpdateNavigationSelection(sender as Button);
        }

        private void NavigateToAbout(object sender, RoutedEventArgs e)
        {
            ShowView(AboutView);
            UpdateNavigationSelection(sender as Button);
        }

        private void ShowView(UIElement viewToShow)
        {
            InspectView.Visibility = Visibility.Collapsed;
            ResultsView.Visibility = Visibility.Collapsed;
            ExportView.Visibility = Visibility.Collapsed;
            AboutView.Visibility = Visibility.Collapsed;
            viewToShow.Visibility = Visibility.Visible;
        }

        private void UpdateNavigationSelection(Button? selectedButton)
        {
            if (selectedButton == null) return;

            var parent = selectedButton.Parent as Panel;
            if (parent == null) return;

            foreach (var child in parent.Children)
            {
                if (child is Button btn)
                {
                    btn.Tag = btn == selectedButton ? "Selected" : null;
                }
            }
        }

        #endregion

        #region Inspect

        private async void RunInspection(object sender, RoutedEventArgs e)
        {
            RunInspectionButton.IsEnabled = false;
            ProgressPanel.Visibility = Visibility.Visible;
            ProgressText.Text = "Running system inspection...";

            var startTime = DateTime.Now;

            try
            {
                _lastScanResult = await _powerShellService.RunInspectionAsync();
                _lastScanTime = startTime;
                _lastScanDuration = DateTime.Now - startTime;

                // Update status panel
                StatusPanel.Visibility = Visibility.Visible;
                LastRunTimestamp.Text = _lastScanTime.Value.ToString("yyyy-MM-dd HH:mm:ss");
                LastRunDuration.Text = $"{_lastScanDuration.Value.TotalSeconds:F1}s";
                LastRunPrivilege.Text = _lastScanResult.Metadata?.IsAdministrator == true ? "Administrator" : "Standard User";

                // Render results
                RenderResults();

                // Switch to results view
                NavigateToResults(null!, null!);

                MessageBox.Show("Inspection completed successfully.", "Success",
                    MessageBoxButton.OK, MessageBoxImage.Information);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Inspection failed:\n\n{ex.Message}", "Error",
                    MessageBoxButton.OK, MessageBoxImage.Error);
            }
            finally
            {
                ProgressPanel.Visibility = Visibility.Collapsed;
                RunInspectionButton.IsEnabled = true;
            }
        }

        #endregion

        #region Results

        private void RenderResults()
        {
            if (_lastScanResult == null)
            {
                return;
            }

            ResultsContent.Children.Clear();

            // System Summary
            AddResultSection("SYSTEM SUMMARY", BuildSystemSummary());

            // Physical Disks
            if (_lastScanResult.PhysicalDisks?.Any() == true)
            {
                AddResultSection("PHYSICAL DISKS", BuildPhysicalDisksView());
            }

            // Volumes
            if (_lastScanResult.Volumes?.Any() == true)
            {
                AddResultSection("VOLUMES", BuildVolumesView());
            }

            // SSD/TRIM Status
            if (_lastScanResult.TrimInfo != null)
            {
                AddResultSection("SSD STATUS", BuildTrimStatusView());
            }

            // Cleanup Candidates
            if (_lastScanResult.UsageBreakdown?.Any() == true)
            {
                AddResultSection("CLEANUP CANDIDATES", BuildCleanupCandidatesView());
            }
        }

        private void AddResultSection(string title, UIElement content)
        {
            var card = new Border
            {
                Style = (Style)FindResource("CardStyle"),
                Margin = new Thickness(0, 0, 0, 16)
            };

            var stack = new StackPanel();

            var titleBlock = new TextBlock
            {
                Text = title,
                FontSize = 11,
                FontWeight = FontWeights.SemiBold,
                Foreground = (SolidColorBrush)FindResource("TextSecondaryBrush"),
                Margin = new Thickness(0, 0, 0, 12)
            };

            stack.Children.Add(titleBlock);
            stack.Children.Add(content);

            card.Child = stack;
            ResultsContent.Children.Add(card);
        }

        private UIElement BuildSystemSummary()
        {
            var grid = new Grid();
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Auto) });
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

            var row = 0;
            AddSummaryRow(grid, ref row, "Computer:", _lastScanResult?.Metadata?.ComputerName ?? "Unknown");
            AddSummaryRow(grid, ref row, "Scan Time:", _lastScanResult?.Metadata?.Timestamp.ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss") ?? "Unknown");
            AddSummaryRow(grid, ref row, "Physical Disks:", _lastScanResult?.Summary?.TotalPhysicalDisks.ToString() ?? "0");
            AddSummaryRow(grid, ref row, "Volumes:", _lastScanResult?.Summary?.TotalVolumes.ToString() ?? "0");
            AddSummaryRow(grid, ref row, "Reclaimable Space:", _lastScanResult?.Summary?.TotalReclaimableFormatted ?? "0 Bytes");

            return grid;
        }

        private void AddSummaryRow(Grid grid, ref int row, string label, string value)
        {
            grid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

            var labelBlock = new TextBlock
            {
                Text = label,
                Foreground = (SolidColorBrush)FindResource("TextSecondaryBrush"),
                Margin = new Thickness(0, 0, 16, 6)
            };
            Grid.SetRow(labelBlock, row);
            Grid.SetColumn(labelBlock, 0);

            var valueBlock = new TextBlock
            {
                Text = value,
                Foreground = (SolidColorBrush)FindResource("TextPrimaryBrush"),
                Margin = new Thickness(0, 0, 0, 6)
            };
            Grid.SetRow(valueBlock, row);
            Grid.SetColumn(valueBlock, 1);

            grid.Children.Add(labelBlock);
            grid.Children.Add(valueBlock);

            row++;
        }

        private UIElement BuildPhysicalDisksView()
        {
            var stack = new StackPanel();

            foreach (var disk in _lastScanResult!.PhysicalDisks!)
            {
                var diskCard = new Border
                {
                    Background = (SolidColorBrush)FindResource("BackgroundBrush"),
                    BorderBrush = (SolidColorBrush)FindResource("BorderBrush"),
                    BorderThickness = new Thickness(1),
                    CornerRadius = new CornerRadius(4),
                    Padding = new Thickness(12),
                    Margin = new Thickness(0, 0, 0, 8)
                };

                var diskStack = new StackPanel();

                var diskTitle = new TextBlock
                {
                    Text = $"Disk {disk.DeviceId}: {disk.FriendlyName}",
                    FontWeight = FontWeights.SemiBold,
                    Margin = new Thickness(0, 0, 0, 8)
                };
                diskStack.Children.Add(diskTitle);

                var infoGrid = new Grid();
                infoGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Auto) });
                infoGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

                var row = 0;
                AddInfoRow(infoGrid, ref row, "Type:", disk.MediaType ?? "Unknown");
                AddInfoRow(infoGrid, ref row, "Size:", disk.SizeFormatted ?? "Unknown");
                AddInfoRow(infoGrid, ref row, "Health:", disk.HealthStatus ?? "Unknown",
                    GetHealthColor(disk.HealthStatus));

                diskStack.Children.Add(infoGrid);
                diskCard.Child = diskStack;
                stack.Children.Add(diskCard);
            }

            return stack;
        }

        private UIElement BuildVolumesView()
        {
            var stack = new StackPanel();

            foreach (var vol in _lastScanResult!.Volumes!)
            {
                var volCard = new Border
                {
                    Background = (SolidColorBrush)FindResource("BackgroundBrush"),
                    BorderBrush = (SolidColorBrush)FindResource("BorderBrush"),
                    BorderThickness = new Thickness(1),
                    CornerRadius = new CornerRadius(4),
                    Padding = new Thickness(12),
                    Margin = new Thickness(0, 0, 0, 8)
                };

                var volStack = new StackPanel();

                var volTitle = new TextBlock
                {
                    Text = $"{vol.DriveLetter} {vol.VolumeName} ({vol.FileSystem})",
                    FontWeight = FontWeights.SemiBold,
                    Margin = new Thickness(0, 0, 0, 8)
                };
                volStack.Children.Add(volTitle);

                // Usage bar
                var barBorder = new Border
                {
                    Height = 8,
                    Background = (SolidColorBrush)FindResource("BorderBrush"),
                    CornerRadius = new CornerRadius(4),
                    Margin = new Thickness(0, 0, 0, 8)
                };

                var barFill = new Border
                {
                    Width = Math.Max(0, vol.PercentUsed),
                    HorizontalAlignment = HorizontalAlignment.Left,
                    Background = new SolidColorBrush(GetVolumeStatusColor(vol.Status)),
                    CornerRadius = new CornerRadius(4)
                };

                var barGrid = new Grid();
                barGrid.Children.Add(barFill);
                barBorder.Child = barGrid;
                volStack.Children.Add(barBorder);

                var usageText = new TextBlock
                {
                    Text = $"{vol.UsedSpaceFormatted} used of {vol.TotalSizeFormatted} ({vol.PercentFree:F1}% free)",
                    FontSize = 11,
                    Foreground = (SolidColorBrush)FindResource("TextSecondaryBrush")
                };
                volStack.Children.Add(usageText);

                volCard.Child = volStack;
                stack.Children.Add(volCard);
            }

            return stack;
        }

        private UIElement BuildTrimStatusView()
        {
            var stack = new StackPanel();

            var trimStatus = new TextBlock
            {
                Text = _lastScanResult!.TrimInfo!.TrimEnabled ? "TRIM: Enabled" : "TRIM: Disabled",
                Foreground = _lastScanResult.TrimInfo.TrimEnabled
                    ? (SolidColorBrush)FindResource("SuccessBrush")
                    : (SolidColorBrush)FindResource("WarningBrush"),
                FontWeight = FontWeights.SemiBold,
                Margin = new Thickness(0, 0, 0, 4)
            };
            stack.Children.Add(trimStatus);

            var details = new TextBlock
            {
                Text = _lastScanResult.TrimInfo.Details ?? "",
                Foreground = (SolidColorBrush)FindResource("TextSecondaryBrush"),
                TextWrapping = TextWrapping.Wrap
            };
            stack.Children.Add(details);

            return stack;
        }

        private UIElement BuildCleanupCandidatesView()
        {
            var stack = new StackPanel();

            var totalText = new TextBlock
            {
                Text = $"Total potentially reclaimable: {_lastScanResult!.Summary?.TotalReclaimableFormatted}",
                Foreground = (SolidColorBrush)FindResource("WarningBrush"),
                FontWeight = FontWeights.SemiBold,
                Margin = new Thickness(0, 0, 0, 12)
            };
            stack.Children.Add(totalText);

            foreach (var item in _lastScanResult.UsageBreakdown!.Where(u => u.Size > 0))
            {
                var itemGrid = new Grid { Margin = new Thickness(0, 0, 0, 8) };
                itemGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
                itemGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Auto) });

                var categoryText = new TextBlock
                {
                    Text = item.Category ?? "Unknown",
                    Foreground = (SolidColorBrush)FindResource("TextPrimaryBrush")
                };
                Grid.SetColumn(categoryText, 0);

                var sizeText = new TextBlock
                {
                    Text = item.SizeFormatted ?? "0",
                    Foreground = (SolidColorBrush)FindResource("TextSecondaryBrush"),
                    HorizontalAlignment = HorizontalAlignment.Right
                };
                Grid.SetColumn(sizeText, 1);

                itemGrid.Children.Add(categoryText);
                itemGrid.Children.Add(sizeText);
                stack.Children.Add(itemGrid);
            }

            var separator = new Border
            {
                Height = 1,
                Background = (SolidColorBrush)FindResource("BorderBrush"),
                Margin = new Thickness(0, 12, 0, 12)
            };
            stack.Children.Add(separator);

            var cleanupButton = new Button
            {
                Content = "Open Windows Disk Cleanup",
                Style = (Style)FindResource("SecondaryButtonStyle"),
                HorizontalAlignment = HorizontalAlignment.Left
            };
            cleanupButton.Click += LaunchDiskCleanup;
            stack.Children.Add(cleanupButton);

            return stack;
        }

        private void AddInfoRow(Grid grid, ref int row, string label, string value, SolidColorBrush? valueColor = null)
        {
            grid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });

            var labelBlock = new TextBlock
            {
                Text = label,
                Foreground = (SolidColorBrush)FindResource("TextSecondaryBrush"),
                Margin = new Thickness(0, 0, 12, 4),
                FontSize = 11
            };
            Grid.SetRow(labelBlock, row);
            Grid.SetColumn(labelBlock, 0);

            var valueBlock = new TextBlock
            {
                Text = value,
                Foreground = valueColor ?? (SolidColorBrush)FindResource("TextPrimaryBrush"),
                Margin = new Thickness(0, 0, 0, 4),
                FontSize = 11
            };
            Grid.SetRow(valueBlock, row);
            Grid.SetColumn(valueBlock, 1);

            grid.Children.Add(labelBlock);
            grid.Children.Add(valueBlock);

            row++;
        }

        private SolidColorBrush GetHealthColor(string? health)
        {
            return health switch
            {
                "Healthy" => (SolidColorBrush)FindResource("SuccessBrush"),
                "Warning" => (SolidColorBrush)FindResource("WarningBrush"),
                "Unhealthy" => (SolidColorBrush)FindResource("ErrorBrush"),
                _ => (SolidColorBrush)FindResource("TextSecondaryBrush")
            };
        }

        private Color GetVolumeStatusColor(string? status)
        {
            return status switch
            {
                "Healthy" => ((SolidColorBrush)FindResource("SuccessBrush")).Color,
                "Warning" => ((SolidColorBrush)FindResource("WarningBrush")).Color,
                "Critical" => ((SolidColorBrush)FindResource("ErrorBrush")).Color,
                _ => ((SolidColorBrush)FindResource("TextSecondaryBrush")).Color
            };
        }

        private void LaunchDiskCleanup(object sender, RoutedEventArgs e)
        {
            try
            {
                _powerShellService.LaunchDiskCleanup("C");
                MessageBox.Show("Windows Disk Cleanup has been launched.\n\nReview and select cleanup categories in the Disk Cleanup window.",
                    "Disk Cleanup Launched", MessageBoxButton.OK, MessageBoxImage.Information);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Failed to launch Disk Cleanup:\n\n{ex.Message}", "Error",
                    MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        #endregion

        #region Export

        private void BrowseExportPath(object sender, RoutedEventArgs e)
        {
            var dialog = new Microsoft.Win32.SaveFileDialog
            {
                Title = "Select Export Location",
                Filter = "Folder|*.folder",
                FileName = "Select Folder"
            };

            if (dialog.ShowDialog() == true)
            {
                var path = System.IO.Path.GetDirectoryName(dialog.FileName);
                if (!string.IsNullOrEmpty(path))
                {
                    ExportPathTextBox.Text = path;
                }
            }
        }

        private async void ExportReport(object sender, RoutedEventArgs e)
        {
            if (_lastScanResult == null)
            {
                MessageBox.Show("No scan results available. Please run an inspection first.",
                    "No Results", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            ExportButton.IsEnabled = false;

            try
            {
                var format = HtmlFormatRadio.IsChecked == true ? "HTML" : "Text";
                var outputPath = ExportPathTextBox.Text;

                var reportPath = await _powerShellService.ExportReportAsync(format, outputPath);

                MessageBox.Show($"Report exported successfully:\n\n{reportPath}",
                    "Export Complete", MessageBoxButton.OK, MessageBoxImage.Information);

                if (OpenAfterExportCheckBox.IsChecked == true && File.Exists(reportPath))
                {
                    Process.Start(new ProcessStartInfo
                    {
                        FileName = reportPath,
                        UseShellExecute = true
                    });
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Export failed:\n\n{ex.Message}", "Error",
                    MessageBoxButton.OK, MessageBoxImage.Error);
            }
            finally
            {
                ExportButton.IsEnabled = true;
            }
        }

        #endregion

        #region About

        private void ViewScriptSource(object sender, RoutedEventArgs e)
        {
            try
            {
                _powerShellService.OpenScriptFile();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Failed to open script file:\n\n{ex.Message}", "Error",
                    MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        #endregion
    }
}
