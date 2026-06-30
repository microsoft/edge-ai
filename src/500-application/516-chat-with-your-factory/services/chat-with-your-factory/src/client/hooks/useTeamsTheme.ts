import { useState, useEffect } from 'react'
import * as microsoftTeams from '@microsoft/teams-js'
import {
  teamsLightTheme,
  teamsDarkTheme,
  teamsHighContrastTheme,
  type Theme,
} from '@fluentui/react-components'

function mapTeamsTheme(themeString: string | undefined): Theme {
  switch (themeString) {
    case 'dark':
      return teamsDarkTheme
    case 'contrast':
      return teamsHighContrastTheme
    default:
      return teamsLightTheme
  }
}

export function useTeamsTheme() {
  const [theme, setTheme] = useState<Theme>(teamsLightTheme)

  useEffect(() => {
    microsoftTeams.app.initialize().then(() => {
      microsoftTeams.app.getContext().then((context) => {
        setTheme(mapTeamsTheme(context.app.theme))
      })
      microsoftTeams.app.registerOnThemeChangeHandler((newTheme: string) => {
        setTheme(mapTeamsTheme(newTheme))
      })
      microsoftTeams.app.notifySuccess()
    }).catch(() => {
      // Standalone mode — keep default light theme
    })
  }, [])

  return theme
}
