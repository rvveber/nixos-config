// Project-wide GJS/AGS declarations that are not provided by generated GIR files.
declare namespace JSX {
  type Element = unknown

  interface IntrinsicElements {
    [elementName: string]: any
  }
}

declare module "*.scss" {
  const css: string
  export default css
}
