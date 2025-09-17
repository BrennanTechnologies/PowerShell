function Refresh-Explorer {
	if (-not ([System.Management.Automation.PSTypeName]'RefreshExplorer').Type) {
		$code = @"
using System;
{
    private static readonly IntPtr HWND_BROADCAST = new IntPtr(0xffff);
    private const uint WM_SETTINGCHANGE = (uint)0x1a;
    private const uint SHCNE_ASSOCCHANGED = (uint)0x08000000L;
    private const uint SHCNF_FLUSH = (uint)0x1000;

    [System.Runtime.InteropServices.DllImport("user32.dll", SetLastError = true)]
    private static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, IntPtr wParam, string lParam, uint fuFlags, uint uTimeout, IntPtr lpdwResult);

    [System.Runtime.InteropServices.DllImport("Shell32.dll")]
    private static extern int SHChangeNotify(uint eventId, uint flags, IntPtr item1, IntPtr item2);

    public static void Refresh() {
        SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_FLUSH, IntPtr.Zero, IntPtr.Zero);
    }
}
"@
	}
	try {
		Add-Type -TypeDefinition $code -Language CSharp
	}
	catch {
		Write-Host "Error adding type: $_"
		if ($_.Exception -is [System.Management.Automation.ParseException]) {
			$_.Exception.Errors | ForEach-Object {
				Write-Host ("Line {0}: {1}" -f $_.Line, $_.Message)
			}
		}

		try {
			[RefreshExplorer]::Refresh()
		}
		catch {
			Write-Host "Error calling Refresh: $_"
		}
	}
}
# Call the function to refresh the registry
Refresh-Explorer