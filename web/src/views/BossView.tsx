import { useState } from 'react'
import {
    TrendingUp, BedDouble, Users, MessageSquare,
    Edit3, UserX, AlertTriangle, CheckCircle2, Clock,
} from 'lucide-react'
import type { Dashboard, Room, Tenant, Complaint } from '../types'
import { nuiPost } from '../nui'

function formatExpiry(ts: number) {
    const diff = ts - Math.floor(Date.now() / 1000)
    if (diff <= 0) return 'Expired'
    const h = Math.floor(diff / 3600)
    const m = Math.floor((diff % 3600) / 60)
    return h > 0 ? `${h}h ${m}m` : `${m}m`
}
function shortId(id: string) {
    return (id.split(':').pop() ?? id).slice(-8).toUpperCase()
}
function roomLabel(rooms: Room[], id: number) {
    return rooms.find(r => r.id === id)?.label ?? `Room ${id}`
}

type Tab = 'overview' | 'rooms' | 'tenants' | 'complaints'

export default function BossView({ dashboard }: { dashboard: Dashboard }) {
    const [tab, setTab] = useState<Tab>('overview')
    const [complaints, setComplaints] = useState(dashboard.complaints ?? [])

    const rooms    = dashboard.rooms    ?? []
    const tenants  = dashboard.tenants  ?? []
    const openCount = complaints.filter(c => c.status !== 'resolved').length

    return (
        <>
            <div className="page-head">
                <div>
                    <p className="page-title">Management</p>
                    <p className="page-sub">Hotel overview and operations</p>
                </div>
            </div>

            <div className="stats-row">
                <div className="stat-card">
                    <p className="stat-value">{dashboard.activeRooms}</p>
                    <p className="stat-label">Occupied</p>
                </div>
                <div className="stat-card">
                    <p className="stat-value">${(dashboard.revenue ?? 0).toLocaleString()}</p>
                    <p className="stat-label">Revenue</p>
                </div>
                <div className="stat-card">
                    <p className="stat-value">{tenants.length}</p>
                    <p className="stat-label">Tenants</p>
                </div>
            </div>

            <div className="tabs">
                <button className={`tab${tab === 'overview'   ? ' active' : ''}`} onClick={() => setTab('overview')}>
                    <TrendingUp size={13} /> Overview
                </button>
                <button className={`tab${tab === 'rooms'      ? ' active' : ''}`} onClick={() => setTab('rooms')}>
                    <BedDouble size={13} /> Rooms
                </button>
                <button className={`tab${tab === 'tenants'    ? ' active' : ''}`} onClick={() => setTab('tenants')}>
                    <Users size={13} /> Tenants
                    {tenants.length > 0 && <span className="tab-count">{tenants.length}</span>}
                </button>
                <button className={`tab${tab === 'complaints' ? ' active' : ''}`} onClick={() => setTab('complaints')}>
                    <MessageSquare size={13} /> Complaints
                    {openCount > 0 && <span className="tab-count">{openCount}</span>}
                </button>
            </div>

            {tab === 'overview'   && <OverviewTab dashboard={dashboard} openCount={openCount} onTab={setTab} />}
            {tab === 'rooms'      && <RoomsTab rooms={rooms} tenants={tenants} />}
            {tab === 'tenants'    && <TenantsTab tenants={tenants} rooms={rooms} />}
            {tab === 'complaints' && (
                <ComplaintsTab
                    complaints={complaints}
                    onChange={setComplaints}
                />
            )}
        </>
    )
}

function OverviewTab({ dashboard, openCount, onTab }: {
    dashboard: Dashboard
    openCount: number
    onTab: (t: Tab) => void
}) {
    const rooms   = dashboard.rooms   ?? []
    const tenants = dashboard.tenants ?? []

    return (
        <>
            {openCount > 0 && (
                <div
                    style={{ background: 'var(--err-dim)', border: '1px solid var(--err-border)', borderRadius: 'var(--r-lg)', padding: '12px 15px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14, cursor: 'pointer' }}
                    onClick={() => onTab('complaints')}
                >
                    <span style={{ fontSize: 13, fontWeight: 600, color: 'var(--err)', display: 'flex', alignItems: 'center', gap: 8 }}>
                        <AlertTriangle size={14} /> {openCount} open complaint{openCount !== 1 ? 's' : ''}
                    </span>
                    <span style={{ fontSize: 11, color: 'var(--text-2)' }}>View →</span>
                </div>
            )}

            <p className="section-label">Recent Tenants</p>
            {tenants.length === 0 ? (
                <div className="empty" style={{ padding: '24px 0' }}>
                    <div className="empty-icon"><Users size={24} /></div>
                    <p>No active tenants.</p>
                </div>
            ) : (
                tenants.slice(0, 4).map(t => (
                    <div className="list-row" key={t.identifier + t.room}>
                        <div className="list-row-top">
                            <span className="list-row-title">{roomLabel(rooms, Number(t.room))}</span>
                            <span className="badge badge-ok"><Clock size={8} /> {formatExpiry(t.expires)}</span>
                        </div>
                        <p className="list-row-sub">ID: {shortId(t.identifier)}</p>
                    </div>
                ))
            )}
        </>
    )
}

function RoomsTab({ rooms, tenants }: { rooms: Room[]; tenants: Tenant[] }) {
    const [editId,    setEditId]    = useState<number | null>(null)
    const [priceVal,  setPriceVal]  = useState('')

    function tenantFor(roomId: number) {
        return tenants.find(t => Number(t.room) === roomId)
    }

    async function savePrice(roomId: number) {
        const p = parseFloat(priceVal)
        if (isNaN(p) || p < 0) return
        await nuiPost('bossChangePrice', { roomId, price: p })
        setEditId(null)
        setPriceVal('')
    }

    async function evict(identifier: string) {
        await nuiPost('bossEvict', { identifier })
    }

    if (!rooms.length) return <div className="empty"><div className="empty-icon"><BedDouble size={28} /></div><p>No rooms found.</p></div>

    return (
        <>
            {rooms.map(room => {
                const tenant   = tenantFor(room.id)
                const occupied = !!tenant
                return (
                    <div className="list-row" key={room.id}>
                        <div className="list-row-top">
                            <span className="list-row-title">{room.label ?? `Room ${room.id}`}</span>
                            <div style={{ display: 'flex', gap: 5, alignItems: 'center' }}>
                                <span className="badge badge-neutral">${room.price} / {room.duration}h</span>
                                {occupied
                                    ? <span className="badge badge-err"><Users size={8} /> Occupied</span>
                                    : <span className="badge badge-ok"><CheckCircle2 size={8} /> Free</span>
                                }
                                {room.state && room.state !== 'clean' && (
                                    <span className="badge badge-warn">{room.state}</span>
                                )}
                            </div>
                        </div>
                        {tenant && (
                            <p className="list-row-sub">
                                Tenant: {shortId(tenant.identifier)} · expires in {formatExpiry(tenant.expires)}
                            </p>
                        )}

                        {editId === room.id ? (
                            <div className="price-edit-row">
                                <input
                                    type="number"
                                    placeholder={`Current: $${room.price}`}
                                    value={priceVal}
                                    onChange={e => setPriceVal(e.target.value)}
                                    autoFocus
                                />
                                <button className="btn btn-pink" style={{ padding: '5px 14px', fontSize: 11 }} onClick={() => savePrice(room.id)}>Save</button>
                                <button className="btn btn-ghost" style={{ padding: '5px 14px', fontSize: 11 }} onClick={() => { setEditId(null); setPriceVal('') }}>✕</button>
                            </div>
                        ) : (
                            <div className="list-row-actions">
                                <button className="btn btn-ghost" style={{ padding: '5px 12px', fontSize: 11 }}
                                    onClick={() => { setEditId(room.id); setPriceVal(String(room.price)) }}>
                                    <Edit3 size={11} /> Edit Price
                                </button>
                                {tenant && (
                                    <button className="btn btn-err" style={{ padding: '5px 12px', fontSize: 11 }}
                                        onClick={() => evict(tenant.identifier)}>
                                        <UserX size={11} /> Evict
                                    </button>
                                )}
                            </div>
                        )}
                    </div>
                )
            })}
        </>
    )
}

function TenantsTab({ tenants, rooms }: { tenants: Tenant[]; rooms: Room[] }) {
    const [fineTarget, setFineTarget] = useState<Tenant | null>(null)
    const [amount,     setAmount]     = useState('')
    const [reason,     setReason]     = useState('')
    const [loading,    setLoading]    = useState(false)

    async function evict(identifier: string) { await nuiPost('bossEvict', { identifier }) }

    async function issueFine() {
        if (!fineTarget) return
        const n = parseFloat(amount)
        if (isNaN(n) || n <= 0) return
        setLoading(true)
        await nuiPost('bossFine', { identifier: fineTarget.identifier, amount: n, reason: reason || 'Hotel fine' })
        setLoading(false)
        setFineTarget(null)
        setAmount(''); setReason('')
    }

    if (!tenants.length) return <div className="empty"><div className="empty-icon"><Users size={28} /></div><p>No active tenants.</p></div>

    return (
        <>
            {tenants.map(t => (
                <div className="list-row" key={t.identifier + t.room}>
                    <div className="list-row-top">
                        <span className="list-row-title">{roomLabel(rooms, Number(t.room))}</span>
                        <span className="badge badge-ok"><Clock size={8} /> {formatExpiry(t.expires)} left</span>
                    </div>
                    <p className="list-row-sub">ID: {shortId(t.identifier)}</p>
                    <div className="list-row-actions">
                        <button className="btn btn-warn" style={{ padding: '5px 12px', fontSize: 11 }}
                            onClick={() => { setFineTarget(t); setAmount(''); setReason('') }}>
                            <AlertTriangle size={11} /> Fine
                        </button>
                        <button className="btn btn-err" style={{ padding: '5px 12px', fontSize: 11 }}
                            onClick={() => evict(t.identifier)}>
                            <UserX size={11} /> Evict
                        </button>
                    </div>
                </div>
            ))}

            {fineTarget && (
                <div className="modal-backdrop" onClick={e => { if (e.target === e.currentTarget) setFineTarget(null) }}>
                    <div className="modal">
                        <p className="modal-title"><AlertTriangle size={15} /> Issue Fine</p>
                        <p style={{ fontSize: 12, color: 'var(--text-2)', marginBottom: 14 }}>
                            Tenant: <span style={{ color: 'var(--text-1)', fontWeight: 600 }}>{shortId(fineTarget.identifier)}</span>
                        </p>
                        <div className="field-group">
                            <label className="field-label">Amount ($)</label>
                            <input className="field-input" type="number" placeholder="e.g. 500" value={amount} onChange={e => setAmount(e.target.value)} />
                        </div>
                        <div className="field-group">
                            <label className="field-label">Reason</label>
                            <input className="field-input" type="text" placeholder="Hotel fine" value={reason} onChange={e => setReason(e.target.value)} />
                        </div>
                        <div className="modal-actions">
                            <button className="btn btn-pink" onClick={issueFine} disabled={loading || !amount}>
                                {loading ? 'Processing…' : 'Issue Fine'}
                            </button>
                            <button className="btn btn-ghost" onClick={() => setFineTarget(null)}>Cancel</button>
                        </div>
                    </div>
                </div>
            )}
        </>
    )
}

function ComplaintsTab({ complaints, onChange }: { complaints: Complaint[]; onChange: (c: Complaint[]) => void }) {
    const [resolving, setResolving] = useState<number | null>(null)

    async function resolve(id: number) {
        setResolving(id)
        await nuiPost('resolveComplaint', { id })
        onChange(complaints.map(c => c.id === id ? { ...c, status: 'resolved' as const } : c))
        setResolving(null)
    }

    const open     = complaints.filter(c => c.status !== 'resolved')
    const resolved = complaints.filter(c => c.status === 'resolved')

    if (!complaints.length) return <div className="empty"><div className="empty-icon"><CheckCircle2 size={28} /></div><p>No complaints on record.</p></div>

    return (
        <>
            {open.length > 0 && (
                <>
                    <p className="section-label">Open ({open.length})</p>
                    {open.map(c => <BossComplaintCard key={c.id} c={c} onResolve={resolve} loading={resolving === c.id} />)}
                </>
            )}
            {resolved.length > 0 && (
                <>
                    <p className="section-label" style={{ marginTop: 14 }}>Resolved ({resolved.length})</p>
                    {resolved.map(c => <BossComplaintCard key={c.id} c={c} onResolve={resolve} loading={false} />)}
                </>
            )}
        </>
    )
}

function BossComplaintCard({ c, onResolve, loading }: { c: Complaint; onResolve: (id: number) => void; loading: boolean }) {
    const resolved = c.status === 'resolved'
    const meta = [
        c.identifier ? `ID: ${shortId(c.identifier)}` : null,
        c.room       ? `Room ${c.room}` : null,
        c.created_at ? new Date(c.created_at * 1000).toLocaleDateString() : null,
    ].filter(Boolean).join(' · ')

    return (
        <div className={`complaint-card${resolved ? ' resolved' : ''}`}>
            <div className="complaint-top">
                <span className="complaint-title">{c.category ?? 'General'}</span>
                {resolved
                    ? <span className="badge badge-resolved"><CheckCircle2 size={8} /> Resolved</span>
                    : <span className="badge badge-err">Open</span>
                }
            </div>
            <p className="complaint-body">{c.message}</p>
            <div className="complaint-footer">
                <span className="complaint-meta">{meta}</span>
                {!resolved && (
                    <button className="btn btn-ok" onClick={() => onResolve(c.id)} disabled={loading} style={{ padding: '5px 12px', fontSize: 11 }}>
                        {loading ? '…' : <><CheckCircle2 size={11} /> Resolve</>}
                    </button>
                )}
            </div>
        </div>
    )
}
