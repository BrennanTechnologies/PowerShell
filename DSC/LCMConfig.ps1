[DSCLocalConfigurationManager()]
configuration LCMConfig
{
	Node localhost
	{
		Settings {
			RefreshMode                    = 'Push'
			ConfigurationMode              = 'ApplyAndAutoCorrect'
			ConfigurationModeFrequencyMins = 15
			RebootNodeIfNeeded             = $true
			ConfigurationID                = '7ZipDSC'
		}
	}
}
LCMConfig