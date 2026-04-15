param(
    [Parameter(Mandatory = $true)]
    [string] $InputPath,

    [Parameter(Mandatory = $true)]
    [string] $OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$pythonScript = @'
import sys
import textwrap

input_path = sys.argv[1]
output_path = sys.argv[2]

with open(input_path, "r", encoding="utf-8") as f:
    lines = f.read().splitlines()

wrapped = []
for raw in lines:
    line = raw.replace("\t", "    ")
    if not line:
        wrapped.append("")
        continue
    wrapped.extend(textwrap.wrap(line, width=95, replace_whitespace=False, drop_whitespace=False) or [""])

page_width = 612
page_height = 792
left_margin = 54
top_margin = 54
font_size = 10
leading = 13
lines_per_page = int((page_height - (top_margin * 2)) / leading)

pages = []
for i in range(0, len(wrapped), lines_per_page):
    pages.append(wrapped[i:i + lines_per_page])

def esc(text):
    return text.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")

objects = []

def add_object(data):
    objects.append(data)
    return len(objects)

font_obj = add_object("<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>")

page_ids = []
content_ids = []

for page_lines in pages:
    content = ["BT", f"/F1 {font_size} Tf", f"{left_margin} {page_height - top_margin} Td", f"{leading} TL"]
    first = True
    for line in page_lines:
        prefix = "" if first else "T* "
        content.append(f"{prefix}({esc(line)}) Tj")
        first = False
    content.append("ET")
    content_bytes = "\n".join(content).encode("latin-1", errors="replace")
    content_id = add_object(f"<< /Length {len(content_bytes)} >>\nstream\n{content_bytes.decode('latin-1')}\nendstream")
    content_ids.append(content_id)
    page_ids.append(add_object(""))

pages_kids = " ".join(f"{pid} 0 R" for pid in page_ids)
pages_obj = add_object(f"<< /Type /Pages /Kids [ {pages_kids} ] /Count {len(page_ids)} >>")

for idx, page_id in enumerate(page_ids):
    content_id = content_ids[idx]
    objects[page_id - 1] = (
        f"<< /Type /Page /Parent {pages_obj} 0 R /MediaBox [0 0 {page_width} {page_height}] "
        f"/Resources << /Font << /F1 {font_obj} 0 R >> >> /Contents {content_id} 0 R >>"
    )

catalog_obj = add_object(f"<< /Type /Catalog /Pages {pages_obj} 0 R >>")

pdf = bytearray()
pdf.extend(b"%PDF-1.4\n%\xe2\xe3\xcf\xd3\n")
offsets = [0]

for idx, obj in enumerate(objects, start=1):
    offsets.append(len(pdf))
    pdf.extend(f"{idx} 0 obj\n".encode("latin-1"))
    pdf.extend(obj.encode("latin-1"))
    pdf.extend(b"\nendobj\n")

xref_offset = len(pdf)
pdf.extend(f"xref\n0 {len(objects) + 1}\n".encode("latin-1"))
pdf.extend(b"0000000000 65535 f \n")
for off in offsets[1:]:
    pdf.extend(f"{off:010d} 00000 n \n".encode("latin-1"))

pdf.extend(
    (
        f"trailer\n<< /Size {len(objects) + 1} /Root {catalog_obj} 0 R >>\n"
        f"startxref\n{xref_offset}\n%%EOF\n"
    ).encode("latin-1")
)

with open(output_path, "wb") as f:
    f.write(pdf)
'@

$resolvedInput = Resolve-Path -LiteralPath $InputPath
$outputDirectory = Split-Path -Parent $OutputPath

if ($outputDirectory -and -not (Test-Path $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

$tempScript = Join-Path $env:TEMP "new_text_pdf.py"
Set-Content -LiteralPath $tempScript -Value $pythonScript -Encoding UTF8

python $tempScript $resolvedInput $OutputPath

Write-Host "PDF created at $OutputPath"
