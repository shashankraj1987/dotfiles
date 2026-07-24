if (Get-Command winget -ErrorAction SilentlyContinue) {
    Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)

        [System.Management.Automation.CompletionResult]::new($wordToComplete, $wordToComplete, "ParameterValue", $wordToComplete)
    }
}
