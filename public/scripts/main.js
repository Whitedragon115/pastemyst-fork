import { getWordwrap, getFullwidth } from "./helpers/options.js";

    if (localStorage.getItem("theme") === null)
    {
        localStorage.setItem("theme", "bit-fury");
    }
    else
    {
        const themePicker = document.getElementById("theme-picker");
        const theme = localStorage.getItem("theme");

        themePicker.value = theme;
    }

    setTheme();

window.addEventListener("load", () =>
{
    let fullwidthToggle = document.querySelector("nav .fullwidth"),
        wordwrapToggle = document.querySelector("nav .wordwrap");

    fullwidthToggle.addEventListener("click", toggleFullwidth);
    wordwrapToggle.addEventListener("click", toggleWordwrap);

    if (getFullwidth()) { fullwidthToggle.setAttribute("active", ""); }
    if (getWordwrap()) { wordwrapToggle.setAttribute("active", ""); }

    document.getElementById("theme-picker").addEventListener("change", setThemeEvent);

    setFullwidthClasses();

    if (localStorage.getItem("acceptedCookies") === null)
    {
        localStorage.setItem("acceptedCookies", "false");
    }

    if (localStorage.getItem("acceptedCookies") === "false")
    {
        document.querySelector(".cookies").classList.remove("hidden");
    }

    document.querySelector(".cookies a").addEventListener("click", () =>
    {
        localStorage.setItem("acceptedCookies", "true");
        document.querySelector(".cookies").classList.add("hidden");
    });

    setTheme();
});

function toggleFullwidth()
{
    let fullwidth = getFullwidth();

    localStorage.setItem("fullwidth", !fullwidth);
    
    let toggle = document.querySelector("nav .fullwidth");
    if (getFullwidth()) {
        toggle.setAttribute("active", "");
    }
    else {
        toggle.removeAttribute("active");
    }

    setFullwidthClasses();
}

function toggleWordwrap()
{
    let wordwrap = getWordwrap();

    localStorage.setItem("wordwrap", !wordwrap);
    
    let toggle = document.querySelector("nav .wordwrap");
    if (getWordwrap()) {
        toggle.setAttribute("active", "");
    }
    else {
        toggle.removeAttribute("active");
    }

    let editorElements = document.querySelectorAll(".CodeMirror");

    for (let i = 0; i < editorElements.length; i++)
    {
        let editor = editorElements[i].CodeMirror;
        editor.setOption("lineWrapping", !wordwrap);
    }
}

function setFullwidthClasses()
{
    let fullwidth = localStorage.getItem("fullwidth") === "true";

    let container = document.getElementById("container");

    if (fullwidth)
    {
        if (!container.classList.contains("fullwidth"))
        {
            container.classList.add("fullwidth");
        }
    }
    else
    {
        if (container.classList.contains("fullwidth"))
        {
            container.classList.remove("fullwidth");
        }
    }
}

function setThemeEvent(e)
{
    localStorage.setItem("theme", e.target.value);
    setTheme();
}

function setTheme()
{
    const theme = localStorage.getItem("theme");

    let editorElements = document.querySelectorAll(".CodeMirror");

    for (let i = 0; i < editorElements.length; i++)
    {
        let editor = editorElements[i].CodeMirror;
        editor.setOption("theme", theme);
    }

    document.documentElement.classList = theme;
}
