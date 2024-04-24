Function Check-Password-Against-Previous-Password {
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory = $true)]
    [string]$previous_password,
    [Parameter(Mandatory = $true)]
    [string]$new_password
  )
  [string]$previous_pass_char_01 = $previous_password.SubString(0, 1)
  [string]$previous_pass_char_02 = $previous_password.SubString(1, 1)
  [string]$previous_pass_char_03 = $previous_password.SubString(2, 1)
  [string]$previous_pass_char_04 = $previous_password.SubString(3, 1)
  [string]$previous_pass_char_05 = $previous_password.SubString(4, 1)
  [string]$previous_pass_char_06 = $previous_password.SubString(5, 1)
  [string]$previous_pass_char_07 = $previous_password.SubString(6, 1)
  [string]$previous_pass_char_08 = $previous_password.SubString(7, 1)
  [string]$previous_pass_char_09 = $previous_password.SubString(8, 1)
  [string]$previous_pass_char_10 = $previous_password.SubString(9, 1)
  [string]$previous_pass_combo_01 = ($previous_pass_char_01 + $previous_pass_char_02 + $previous_pass_char_03)
  [string]$previous_pass_combo_02 = ($previous_pass_char_02 + $previous_pass_char_03 + $previous_pass_char_04)
  [string]$previous_pass_combo_03 = ($previous_pass_char_03 + $previous_pass_char_04 + $previous_pass_char_05)
  [string]$previous_pass_combo_04 = ($previous_pass_char_04 + $previous_pass_char_05 + $previous_pass_char_06)
  [string]$previous_pass_combo_05 = ($previous_pass_char_05 + $previous_pass_char_06 + $previous_pass_char_07)
  [string]$previous_pass_combo_06 = ($previous_pass_char_06 + $previous_pass_char_07 + $previous_pass_char_08)
  [string]$previous_pass_combo_07 = ($previous_pass_char_07 + $previous_pass_char_08 + $previous_pass_char_09)
  [string]$previous_pass_combo_08 = ($previous_pass_char_08 + $previous_pass_char_09 + $previous_pass_char_10)
  [boolean]$result_01 = $new_password -match $previous_pass_combo_01
  [boolean]$result_02 = $new_password -match $previous_pass_combo_02
  [boolean]$result_03 = $new_password -match $previous_pass_combo_03
  [boolean]$result_04 = $new_password -match $previous_pass_combo_04
  [boolean]$result_05 = $new_password -match $previous_pass_combo_05
  [boolean]$result_06 = $new_password -match $previous_pass_combo_06
  [boolean]$result_07 = $new_password -match $previous_pass_combo_07
  [boolean]$result_08 = $new_password -match $previous_pass_combo_08
  [array]$results_array = @($result_01, $result_02, $result_03, $result_04, $result_05, $result_06, $result_07, $result_08)
  [array]$results_array = $results_array | Sort-Object -Unique
  [int]$results_array_count = $results_array.count
  If ($results_array_count -eq 1) { Return $false }
  Else { Return $true }
}