import { useEffect, useState } from 'react'
import {
    BedDouble, Key, MessageSquare, LayoutDashboard,
    SlidersHorizontal, Building2, X,
} from 'lucide-react'
import './App.css'
import { nuiPost } from './nui'
import type { NuiMessage, Room, Dashboard, Complaint } from './types'
import RoomsView from './views/RoomsView'
import BookingView from './views/BookingView'
import ComplaintsView from './views/ComplaintsView'
import BossView from './views/BossView'
import SettingsView from './views/SettingsView'

const IS_FIVEM = !!(window as any).GetParentResourceName

// ── dev mock ──────────────────────────────────────────────────────
const now = Math.floor(Date.now() / 1000)
const MOCK_ROOMS: Room[] = [
    { id: 1101, label: 'Room 101', price: 250,  duration: 24, available: true,  state: 'clean' },
    { id: 1102, label: 'Room 102', price: 300,  duration: 24, available: false, myRoom: true, expires: now + 82800, state: 'clean' },
    { id: 1103, label: 'Room 103', price: 450,  duration: 48, available: false, state: 'dirty' },
    { id: 1104, label: 'Room 104', price: 200,  duration: 12, available: true,  state: 'clean' },
    { id: 1105, label: 'Suite A',  price: 1200, duration: 24, available: true,  state: 'clean' },
    { id: 1106, label: 'Suite B',  price: 1500, duration: 24, available: false, state: 'clean' },
]
const MOCK_COMPLAINTS: Complaint[] = [
    { id: 1, identifier: 'license:abc123def456', room: 1102, category: 'Noise',       message: 'People next door are very loud at night.', status: 'open',     created_at: now - 3600 },
    { id: 2, identifier: 'license:xyz789uvw012', room: 1103, category: 'Maintenance', message: 'Shower is broken, only cold water.',        status: 'open',     created_at: now - 7200 },
    { id: 3, identifier: 'license:qqq111rrr222', room: 1106, category: 'Billing',     message: 'I was charged twice for my room.',          status: 'resolved', created_at: now - 86400 },
]
const MOCK_DASHBOARD: Dashboard = {
    hotel: 'peak', activeRooms: 3, revenue: 47500,
    tenants: [
        { identifier: 'license:abc123def456', room: 1102, expires: now + 82800 },
        { identifier: 'license:xyz789uvw012', room: 1103, expires: now + 3600 },
        { identifier: 'license:qqq111rrr222', room: 1106, expires: now + 43200 },
    ],
    complaints: MOCK_COMPLAINTS,
    rooms: MOCK_ROOMS,
}

type Page = 'rooms' | 'booking' | 'complaints' | 'boss' | 'settings'

const NAV_ITEMS: { page: Page; label: string; icon: React.ReactNode; bossOnly?: boolean }[] = [
    { page: 'rooms',      label: 'Rooms',      icon: <BedDouble size={16} /> },
    { page: 'booking',    label: 'My Booking', icon: <Key size={16} /> },
    { page: 'complaints', label: 'Complaints', icon: <MessageSquare size={16} /> },
    { page: 'boss',       label: 'Management', icon: <LayoutDashboard size={16} />, bossOnly: true },
    { page: 'settings',   label: 'Settings',   icon: <SlidersHorizontal size={16} /> },
]

export default function App() {
    const [visible,    setVisible]    = useState(!IS_FIVEM)
    const [isBoss,     setIsBoss]     = useState(!IS_FIVEM)
    const [page,       setPage]       = useState<Page>('rooms')
    const [hotelName,  setHotelName]  = useState(!IS_FIVEM ? 'Peak Towers Apartments' : 'Hotel')
    const [hotelSub,   setHotelSub]   = useState(!IS_FIVEM ? 'Premium Accommodation' : '')
    const [rooms,      setRooms]      = useState<Room[]>(!IS_FIVEM ? MOCK_ROOMS : [])
    const [dashboard,  setDashboard]  = useState<Dashboard | null>(!IS_FIVEM ? MOCK_DASHBOARD : null)
    const [complaints, setComplaints] = useState<Complaint[]>(!IS_FIVEM ? MOCK_COMPLAINTS : [])
    const [payment,    setPayment]    = useState<'cash' | 'bank'>('cash')

    useEffect(() => {
        const handler = ({ data }: MessageEvent<NuiMessage>) => {
            if (data.action === 'close') {
                setVisible(false); setIsBoss(false); return
            }
            if (data.action === 'updateRooms') {
                setRooms(data.data.rooms); return
            }
            if (data.action === 'openHotel') {
                setHotelName(data.data.hotelName || data.data.hotel)
                setHotelSub('Premium Accommodation')
                setRooms(data.data.rooms)
                setIsBoss(false)
                setPage('rooms')
                setVisible(true)
            }
            if (data.action === 'openBoss') {
                setHotelName(data.data.hotelName || data.data.hotel)
                setHotelSub('Management Console')
                setDashboard(data.data.dashboard)
                setRooms(data.data.dashboard.rooms || [])
                setIsBoss(true)
                setPage('boss')
                setVisible(true)
            }
            if (data.action === 'openComplaints') {
                setHotelName(data.data.hotelName || data.data.hotel)
                setHotelSub('Complaints')
                setComplaints(data.data.complaints)
                setIsBoss(true)
                setPage('boss')
                setVisible(true)
            }
        }
        window.addEventListener('message', handler)
        return () => window.removeEventListener('message', handler)
    }, [])

    useEffect(() => {
        const handler = (e: KeyboardEvent) => { if (e.key === 'Escape' && visible) handleClose() }
        window.addEventListener('keydown', handler)
        return () => window.removeEventListener('keydown', handler)
    }, [visible])

    async function handleClose() {
        if (IS_FIVEM) await nuiPost('close', {})
        setVisible(false)
        setIsBoss(false)
    }

    if (!visible) return null

    const visibleNav = NAV_ITEMS.filter(n => !n.bossOnly || isBoss)

    return (
        <div className="app">
            {/* Header */}
            <header className="header">
                <div className="header-brand">
                    <div className="header-icon"><Building2 size={16} /></div>
                    <div>
                        <p className="header-title">{hotelName}</p>
                        <p className="header-sub">{hotelSub || 'Premium Accommodation'}</p>
                    </div>
                </div>
                <div className="header-right">
                    <button className="close-btn" onClick={handleClose}><X size={14} /></button>
                </div>
            </header>

            {/* Sidebar */}
            <aside className="sidebar">
                {visibleNav.map(item => (
                    <button
                        key={item.page}
                        className={`nav-item${page === item.page ? ' active' : ''}`}
                        onClick={() => setPage(item.page)}
                    >
                        <span className="nav-icon">{item.icon}</span>
                        {item.label}
                    </button>
                ))}
            </aside>

            {/* Main */}
            <main className="main">
                {page === 'rooms'      && <RoomsView rooms={rooms} payment={payment} />}
                {page === 'booking'    && <BookingView rooms={rooms} />}
                {page === 'complaints' && <ComplaintsView rooms={rooms} isBoss={isBoss} bossComplaints={complaints} />}
                {page === 'boss'       && dashboard && <BossView dashboard={dashboard} />}
                {page === 'settings'   && <SettingsView payment={payment} onPaymentChange={setPayment} />}
            </main>
        </div>
    )
}
