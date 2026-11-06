import { useMemo, useState } from 'react'
import {
  ArrowDownRight, ArrowRight, ArrowUpRight, Award, BookOpen, CalendarDays,
  ChevronDown, CircleHelp, Clock3, Compass, GraduationCap, LayoutDashboard,
  Menu, Play, Search, ShieldCheck, Sparkles, Video, X,
} from 'lucide-react'

type Course = {
  title: string
  developer: string
  destination: string
  category: string
  level: string
  duration: string
  progress: number
  image: string
  accent: string
}

const courses: Course[] = [
  {
    title: 'Dubai property essentials', developer: 'KIVA Academy', destination: 'UAE',
    category: 'Market knowledge', level: 'Foundation', duration: '2h 40m', progress: 62,
    image: 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?auto=format&fit=crop&w=1000&q=85', accent: 'sand',
  },
  {
    title: 'The South African new-build journey', developer: 'KIVA Academy', destination: 'South Africa',
    category: 'Sales practice', level: 'Intermediate', duration: '3h 15m', progress: 0,
    image: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1000&q=85', accent: 'sage',
  },
  {
    title: 'Mauritius: island living and investment', developer: 'KIVA Academy', destination: 'Mauritius',
    category: 'Destination', level: 'Foundation', duration: '1h 50m', progress: 0,
    image: 'https://images.unsplash.com/photo-1514282401047-d79a71a590e8?auto=format&fit=crop&w=1000&q=85', accent: 'blue',
  },
]

const navItems = [
  { name: 'Dashboard', icon: LayoutDashboard },
  { name: 'Explore courses', icon: Compass },
  { name: 'My learning', icon: BookOpen },
  { name: 'Live meetings', icon: Video },
  { name: 'Certifications', icon: Award },
]

function App() {
  const [activeNav, setActiveNav] = useState('Dashboard')
  const [filter, setFilter] = useState('All destinations')
  const [query, setQuery] = useState('')
  const [mobileMenu, setMobileMenu] = useState(false)
  const visibleCourses = useMemo(() => courses.filter((course) => {
    const matchesDestination = filter === 'All destinations' || course.destination === filter
    const matchesQuery = `${course.title} ${course.category} ${course.destination}`.toLowerCase().includes(query.toLowerCase())
    return matchesDestination && matchesQuery
  }), [filter, query])

  const scrollToCourses = () => {
    setActiveNav('Explore courses')
    document.getElementById('courses')?.scrollIntoView({ behavior: 'smooth' })
  }

  return (
    <div className="app-shell">
      <aside className={`sidebar ${mobileMenu ? 'sidebar-open' : ''}`}>
        <div className="brand-lockup">
          <div className="brand-dot" aria-hidden="true" />
          <div><strong>KIVA</strong><span>ACADEMY</span></div>
          <button className="icon-button mobile-close" onClick={() => setMobileMenu(false)} aria-label="Close navigation"><X size={19} /></button>
        </div>
        <div className="sidebar-label">LEARNING SPACE</div>
        <nav aria-label="Main navigation" className="side-nav">
          {navItems.map(({ name, icon: Icon }) => (
            <button key={name} className={`nav-item ${activeNav === name ? 'nav-active' : ''}`} onClick={() => { setActiveNav(name); if (name === 'Explore courses') scrollToCourses(); setMobileMenu(false) }}>
              <Icon size={18} strokeWidth={1.8} /><span>{name}</span>{name === 'Live meetings' && <i className="nav-dot" />}
            </button>
          ))}
        </nav>
        <div className="sidebar-bottom">
          <div className="provider-card">
            <span className="provider-mark"><GraduationCap size={17} /></span>
            <div><strong>Training provider?</strong><small>Bring your expertise to KIVA.</small></div>
            <ArrowUpRight size={15} />
          </div>
          <button className="nav-item help-link"><CircleHelp size={18} /><span>Help & support</span></button>
          <div className="profile-row">
            <div className="avatar">JD</div><div className="profile-name"><strong>Welcome, learner</strong><small>PropKiva Academy</small></div><ChevronDown size={16} />
          </div>
        </div>
      </aside>

      <main className="main-area">
        <header className="topbar">
          <button className="icon-button mobile-menu" onClick={() => setMobileMenu(true)} aria-label="Open navigation"><Menu size={20} /></button>
          <div className="breadcrumb">PropKiva <span className="red-separator">•</span> Academy</div>
          <div className="topbar-right"><span className="status-pill"><span /> Learning workspace</span><button className="icon-button help-top" aria-label="Help"><CircleHelp size={18} /></button></div>
        </header>

        <div className="page-content">
          <section className="welcome-row">
            <div>
              <div className="eyebrow"><Sparkles size={14} /> YOUR PROFESSIONAL LEARNING SPACE</div>
              <h1>Grow your expertise.<br /><span>Open new possibilities.</span></h1>
              <p>Build the knowledge and confidence to guide clients across borders.</p>
            </div>
            <div className="welcome-actions"><button className="button-primary" onClick={scrollToCourses}>Explore courses <ArrowRight size={16} /></button><span>Learn. Qualify. Connect.</span></div>
          </section>

          <section className="hero-panel" aria-label="Continue learning">
            <div className="hero-photo" />
            <div className="hero-copy">
              <div className="hero-kicker"><span className="live-indicator" /> PICK UP WHERE YOU LEFT OFF</div>
              <h2>Dubai property<br />essentials</h2>
              <p>Market fundamentals, buyer conversations and the details that make a difference.</p>
              <div className="hero-progress"><div className="progress-track"><span style={{ width: '62%' }} /></div><span>62% complete</span></div>
              <button className="button-light" onClick={() => setActiveNav('My learning')}><Play size={15} fill="currentColor" /> Continue learning</button>
            </div>
            <div className="hero-tag"><span>UAE</span><i /> 6 modules</div>
          </section>

          <section className="metric-grid" aria-label="Learning overview">
            <article className="metric-card"><div className="metric-icon red"><BookOpen size={18} /></div><div className="metric-title">In progress</div><strong>1 <small>course</small></strong><span className="metric-note">Keep your momentum</span></article>
            <article className="metric-card"><div className="metric-icon olive"><Clock3 size={18} /></div><div className="metric-title">Learning time</div><strong>4.5 <small>hours</small></strong><span className="metric-note">Across your Academy</span></article>
            <article className="metric-card"><div className="metric-icon gold"><Award size={18} /></div><div className="metric-title">Certificates</div><strong>0 <small>earned</small></strong><span className="metric-note">Your next milestone awaits</span></article>
            <article className="metric-card meeting-metric"><div className="metric-icon slate"><CalendarDays size={18} /></div><div className="metric-title">Next live session</div><strong className="metric-empty">Nothing scheduled</strong><button className="text-action" onClick={() => setActiveNav('Live meetings')}>View meetings <ArrowRight size={14} /></button></article>
          </section>

          <section className="courses-section" id="courses">
            <div className="section-heading"><div><div className="eyebrow">CURATED FOR YOUR NEXT STEP</div><h2>Explore learning</h2><p>Practical insight for property professionals working across markets.</p></div><button className="text-action desktop-action" onClick={() => setActiveNav('Explore courses')}>View all courses <ArrowRight size={15} /></button></div>
            <div className="course-tools">
              <label className="search-field"><Search size={17} /><input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search courses or topics" aria-label="Search courses" />{query && <button aria-label="Clear search" onClick={() => setQuery('')}><X size={15} /></button>}</label>
              <label className="filter-field"><span className="sr-only">Destination filter</span><select value={filter} onChange={(e) => setFilter(e.target.value)}><option>All destinations</option><option>UAE</option><option>South Africa</option><option>Mauritius</option></select><ChevronDown size={15} /></label>
            </div>
            <div className="course-grid">
              {visibleCourses.map((course) => <CourseCard key={course.title} course={course} onOpen={() => setActiveNav('Explore courses')} />)}
              {visibleCourses.length === 0 && <div className="empty-state">No courses match those filters. Try another destination or search term.</div>}
            </div>
          </section>

          <section className="bottom-grid">
            <article className="meeting-card"><div className="card-heading"><div><div className="eyebrow">LEARN TOGETHER</div><h3>Meet the people<br />behind the projects.</h3></div><span className="meeting-icon"><Video size={20} /></span></div><p>Join developer-led briefings, ask questions and deepen your understanding in KIVA Meetings.</p><button className="button-outline" onClick={() => setActiveNav('Live meetings')}>Explore live meetings <ArrowRight size={15} /></button><div className="meeting-lines" /></article>
            <article className="cert-card"><div className="cert-top"><span className="cert-icon"><ShieldCheck size={19} /></span><span className="eyebrow">YOUR PROFESSIONAL RECORD</span></div><h3>Knowledge you can<br />stand behind.</h3><p>Complete eligible training and assessments to build a verified record of your learning.</p><button className="text-action" onClick={() => setActiveNav('Certifications')}>View certifications <ArrowRight size={15} /></button><div className="cert-seal"><Award size={38} strokeWidth={1.1} /></div></article>
          </section>
          <footer className="footer"><span>© 2026 PropKiva Academy</span><span>Create <i /> Discover <i /> Connect</span><span>UAE <i /> South Africa <i /> Mauritius</span></footer>
        </div>
      </main>
      {mobileMenu && <button className="scrim" onClick={() => setMobileMenu(false)} aria-label="Close menu" />}
    </div>
  )
}

function CourseCard({ course, onOpen }: { course: Course; onOpen: () => void }) {
  return <article className="course-card">
    <button className="course-image-wrap" onClick={onOpen} aria-label={`Open ${course.title}`}><img src={course.image} alt="" className="course-image" /><span className="destination-chip">{course.destination}</span><span className="course-play"><Play size={14} fill="currentColor" /></span></button>
    <div className="course-content"><div className="course-meta"><span>{course.category}</span><i /> <span>{course.level}</span></div><h3>{course.title}</h3><div className="course-provider">By {course.developer}</div><div className="course-bottom"><span><Clock3 size={14} /> {course.duration}</span><button onClick={onOpen} aria-label={`Start ${course.title}`}><ArrowDownRight size={17} /></button></div>{course.progress > 0 && <div className="card-progress"><span style={{ width: `${course.progress}%` }} /></div>}</div>
  </article>
}

export default App
