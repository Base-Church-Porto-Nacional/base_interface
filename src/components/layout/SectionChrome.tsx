import { useLocation } from 'react-router-dom'
import { findSection, PROFILE_TABS } from '../../navigation/config'
import { SectionAppBar } from './SectionAppBar'

export function SectionChrome() {
  const { pathname } = useLocation()

  if (pathname.startsWith('/perfil')) {
    return <SectionAppBar title="Meu perfil" items={PROFILE_TABS} />
  }

  const section = findSection(pathname)
  if (!section?.subnav?.length) return null

  return <SectionAppBar title={section.label} items={section.subnav} />
}
