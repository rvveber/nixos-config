import { execAsync } from "ags/process"

export type ClipboardEntry = {
  id: string
  preview: string
  binary: boolean
  image: boolean
}

let entries = new Array<ClipboardEntry>()

function parse(line: string): ClipboardEntry | null {
  const separator = line.indexOf("\t")
  if (separator < 1) return null

  const id = line.slice(0, separator)
  const preview = line.slice(separator + 1).replace(/\\n/g, "\n")
  const normalized = preview.toLocaleLowerCase()
  const binary = normalized.includes("binary data")
    || normalized.includes("ftypavif")
    || /[\u0000-\u0008\u000b\u000c\u000e-\u001f\ufffd]/u.test(preview)
  const image = normalized.includes("ftypavif")
    || (binary && /\b(?:avif|bmp|gif|heic|jpe?g|png|tiff?|webp)\b/u.test(normalized))
  return {
    id,
    preview,
    binary,
    image,
  }
}

async function refresh() {
  try {
    const output = await execAsync(["rvveber-fhud-clipboard", "list"])
    entries = output
      .split("\n")
      .map(parse)
      .filter((entry): entry is ClipboardEntry => entry !== null)
  } catch (error) {
    console.error(`Failed to read clipboard history: ${error}`)
  }
}

function query(text: string) {
  const needle = text.trim().toLocaleLowerCase()
  const matches = needle
    ? entries.filter((entry) => entry.preview.toLocaleLowerCase().includes(needle))
    : entries

  return matches.slice(0, 12)
}

async function remove(entry: ClipboardEntry) {
  await execAsync(["rvveber-fhud-clipboard", "delete", entry.id])
  await refresh()
}

async function paste(entry: ClipboardEntry, returnTargetAddress: string | null) {
  const command = ["rvveber-fhud-clipboard", "paste", entry.id]
  if (returnTargetAddress) command.push(returnTargetAddress)
  await execAsync(command)
}

async function thumbnail(entry: ClipboardEntry) {
  return execAsync(["rvveber-fhud-clipboard", "thumbnail", entry.id])
}

export const clipboardService = {
  refresh,
  query,
  remove,
  paste,
  thumbnail,
}
