$lines = Get-Content './README.md'

$urls = @()
$whitelist = @()

$inUrls = $false
$inWhitelist = $false
foreach($line in $lines){
    if(($null -eq $line) -or ($line -eq '')){
        continue
    }

    if($line -match '^>'){continue}

    $line = $line.Trim()
    if($line -eq '## URLS'){
        $inUrls = $true
        $inWhitelist = $false
    }elseif($line -eq '## Whitelisted'){
        $inUrls = $false
        $inWhitelist = $true
    }elseif($inUrls){
        $urls += $line
    }elseif($inWhitelist){
        $whitelist += $line
    }
}


$whitelist += 'localhost'
$whitelist += 'localhost.localdomain'
$whitelist += 'local'
$whitelist += 'broadcasthost'
$whitelist += 'ip6-localhost'
$whitelist += 'ip6-loopback'
$whitelist += 'ip6-localnet'
$whitelist += 'ip6-mcastprefix'
$whitelist += 'ip6-allnodes'
$whitelist += 'ip6-allrouters'
$whitelist += 'ip6-allhosts'
$whitelist += '0.0.0.0'

$i = 0
foreach($url in $urls){
    try{
        Remove-Item "./$($i).txt" -ErrorAction SilentlyContinue
    }catch{}
    Invoke-WebRequest $url -OutFile "./$($i).txt"
    $i++
}

$progressId = get-random -minimum 1000 -Maximum 2222

$strm = New-Object System.IO.StreamWriter('./Master.txt', $false)
$strm.AutoFlush = $false
$reader = $null

try{
    $k = 0
    $master = New-Object Collections.Generic.List[String]
    $master.clear();

    for($j = 0; $j -lt $i; $j++){
        $reader = New-Object System.IO.StreamReader("./$($j).txt")
        try{

            do{
                $url = $reader.ReadLine()
                $k++
                Write-Progress "Building list" `
                               "File $($j + 1) of $($i) | Total lines read $($k) | Non-comment lines written $($master.Count) ($([Math]::Round(($master.count / $k) * 100, 1))%)" `
                               -Id $progressId

                if(($null -eq $url) -or ($url -eq '')){continue}
                if($url -match '^#'){continue}

                $split = $url -split ' '
                if($split.Length -eq 0){continue}
                if($split.Length -eq 1){
                    $url = $split[0]
                }else{
                    $url = $split[1]
                }

                if($whitelist -icontains $url){continue}
                if($master.Contains($url)){continue}
                
                $master.Add($url)
                $strm.WriteLine($url)

            }while($reader.EndOfStream -eq $false)            
        }finally{
            $reader.Close()
        }
    }

}finally{
    Write-Progress -Id $progressId -Completed
    $strm.Flush()
    $strm.Close()
}