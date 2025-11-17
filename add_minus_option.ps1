# Script untuk menambahkan opsi Kupon Minus ke dialog export

$filePath = "d:\Kerjaan\Kupon_BBM\lib\presentation\pages\transaction\transaction_page.dart"
$content = Get-Content $filePath -Raw

# Pattern untuk mencari dan replace
$oldPattern = @"
              const SizedBox\(height: 12\),
              ListTile\(
                leading: const Icon\(Icons\.business, color: Colors\.orange\),
                title: const Text\('Data Satker \(2 Sheet\)'\),
                subtitle: const Text\(
                  'Pertamax, Dexlite',
                  style: TextStyle\(fontSize: 12\),
                \),
"@

$newPattern = @"
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.remove_circle, color: Colors.red),
                title: const Text('Kupon Minus (4 Sheet)'),
                subtitle: const Text(
                  'RAN.PM, DUK.PM, RAN.DX, DUK.DX - Hanya kupon minus',
                  style: TextStyle(fontSize: 12),
                ),
                tileColor: Colors.red.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.red.shade200),
                ),
                onTap: () => Navigator.pop(context, 'minus'),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.business, color: Colors.orange),
                title: const Text('Data Satker (2 Sheet)'),
                subtitle: const Text(
                  'Pertamax, Dexlite - Rekap per satker',
                  style: TextStyle(fontSize: 12),
                ),
"@

$content = $content -replace [regex]::Escape($oldPattern), $newPattern

# Update condition untuk getNopolByKendaraanId
$content = $content -replace "choice == 'kupon' \? _getNopolByKendaraanId : null", "(choice == 'kupon' || choice == 'minus') ? _getNopolByKendaraanId : null"
$content = $content -replace "choice == 'kupon' \? _getJenisRanmorByKendaraanId : null", "(choice == 'kupon' || choice == 'minus') ? _getJenisRanmorByKendaraanId : null"

Set-Content -Path $filePath -Value $content -NoNewline

Write-Host "Updated transaction_page.dart with minus option"
