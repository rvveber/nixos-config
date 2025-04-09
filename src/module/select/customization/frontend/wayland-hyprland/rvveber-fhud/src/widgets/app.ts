import { App } from "astal/gtk4"
import style from "./style.scss"
import Bar from "./widget/Bar"

App.start({
    css: style,
    instanceName: "Bar",
    main() {
        App.get_monitors().map(Bar)
    },
})