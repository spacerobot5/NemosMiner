. .\Include.ps1

try {
    $hashrefinery_Request = Invoke-WebRequest "http://pool.hashrefinery.com/api/status" -UseBasicParsing -Headers @{"Cache-Control" = "no-cache"} | ConvertFrom-Json 
}
catch { return }

if (-not $hashrefinery_Request) {return}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Location = "US"

$hashrefinery_Request | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | foreach {
    $hashrefinery_Host = "$_.us.hashrefinery.com"
    $hashrefinery_Port = $hashrefinery_Request.$_.port
    $hashrefinery_Algorithm = Get-Algorithm $hashrefinery_Request.$_.name
    $hashrefinery_Coin = "Unknown"

    $Divisor = 1000000 * [Double]$HashRefinery_Request.$HashRefinery_Algorithm.mbtc_mh_factor
	
    if ((Get-Stat -Name "$($Name)_$($hashrefinery_Algorithm)_Profit") -eq $null) {$Stat = Set-Stat -Name "$($Name)_$($hashrefinery_Algorithm)_Profit" -Value ([Double]$hashrefinery_Request.$_.estimate_last24h / $Divisor * (1 - ($hashrefinery_Request.$_.fees / 100)))}
    else {$Stat = Set-Stat -Name "$($Name)_$($hashrefinery_Algorithm)_Profit" -Value ([Double]$hashrefinery_Request.$_.estimate_current / $Divisor * (1 - ($hashrefinery_Request.$_.fees / 100)))}

    $ConfName = if ($Config.PoolsConfig.$Name -ne $Null) {$Name}else {"default"}
    $PwdCurr = if ($Config.PoolsConfig.$ConfName.PwdCurrency) {$Config.PoolsConfig.$ConfName.PwdCurrency}else {$Config.Passwordcurrency}
	
    if ($Config.PoolsConfig.default.Wallet) {
        [PSCustomObject]@{
            Algorithm     = $hashrefinery_Algorithm
            Info          = $hashrefinery
            Price         = $Stat.Live * $Config.PoolsConfig.$ConfName.PricePenaltyFactor
            StablePrice   = $Stat.Week
            MarginOfError = $Stat.Fluctuation
            Protocol      = "stratum+tcp"
            Host          = $hashrefinery_Host
            Port          = $hashrefinery_Port
            User          = $Config.PoolsConfig.$ConfName.Wallet
            Pass          = "$($Config.PoolsConfig.$ConfName.WorkerName),c=$($PwdCurr)"
            Location      = $Location
            SSL           = $false
        }
    }
}
