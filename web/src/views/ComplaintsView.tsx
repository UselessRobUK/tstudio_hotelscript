import { useState } from 'react'
import { CheckCircle2, MessageSquare } from 'lucide-react'
import type { Room, Complaint } from '../types'
import { nuiPost } from '../nui'

const CATEGORIES = ['Noise', 'Maintenance', 'Billing', 'Security', 'Other']

function shortId(id: string) {
    const v = id.split(':').pop() ?? id
    return v.slice(-8).toUpperCase()
}

interface Props {
    rooms: Room[]
    isBoss: boolean
    bossComplaints: Complaint[]
}

export default function ComplaintsView({ rooms, isBoss, bossComplaints }: Props) {
    const myRoom = rooms.find(r => r.myRoom)

    const [category,   setCategory]  = useState('Noise')
    const [message,    setMessage]   = useState('')
    const [submitting, setSubmitting] = useState(false)
    const [done,       setDone]      = useState(false)

    const [list,      setList]      = useState(bossComplaints)
    const [resolving, setResolving] = useState<number | null>(null)

    async function handleSubmit() {
        if (!message.trim()) return
        setSubmitting(true)
        await nuiPost('submitComplaint', { category, message, roomId: myRoom?.id })
        setSubmitting(false)
        setMessage('')
        setDone(true)
        setTimeout(() => setDone(false), 4000)
    }

    async function handleResolve(id: number) {
        setResolving(id)
        await nuiPost('resolveComplaint', { id })
        setList(prev => prev.map(c => c.id === id ? { ...c, status: 'resolved' as const } : c))
        setResolving(null)
    }

    if (isBoss) {
        const open     = list.filter(c => c.status !== 'resolved')
        const resolved = list.filter(c => c.status === 'resolved')
        return (
            <>
                <div className="page-head">
                    <div>
                        <p className="page-title">Complaints</p>
                        <p className="page-sub">{open.length} open · {resolved.length} resolved</p>
                    </div>
                </div>
                {list.length === 0 ? (
                    <div className="empty">
                        <div className="empty-icon"><CheckCircle2 size={30} /></div>
                        <p>No complaints on record.</p>
                    </div>
                ) : (
                    <>
                        {open.length > 0 && (
                            <>{/* section-label */}
                                <p className="section-label">Open ({open.length})</p>
                                {open.map(c => <ComplaintCard key={c.id} c={c} onResolve={handleResolve} loading={resolving === c.id} />)}
                            </>
                        )}
                        {resolved.length > 0 && (
                            <>
                                <p className="section-label" style={{ marginTop: 16 }}>Resolved ({resolved.length})</p>
                                {resolved.map(c => <ComplaintCard key={c.id} c={c} onResolve={handleResolve} loading={false} />)}
                            </>
                        )}
                    </>
                )}
            </>
        )
    }

    return (
        <>
            <div className="page-head">
                <div>
                    <p className="page-title">Submit a Complaint</p>
                    <p className="page-sub">We'll review it as soon as possible</p>
                </div>
            </div>
            <div className="form-wrap">
                {done && (
                    <div className="success-banner" style={{ marginBottom: 14 }}>
                        <CheckCircle2 size={14} /> Complaint submitted. We'll look into it shortly.
                    </div>
                )}
                <div className="field-group">
                    <label className="field-label">Category</label>
                    <select className="field-select" value={category} onChange={e => setCategory(e.target.value)}>
                        {CATEGORIES.map(c => <option key={c}>{c}</option>)}
                    </select>
                </div>
                {myRoom && (
                    <div className="field-group">
                        <label className="field-label">Regarding</label>
                        <input className="field-input" value={myRoom.label ?? `Room ${myRoom.id}`} readOnly />
                    </div>
                )}
                <div className="field-group">
                    <label className="field-label">Message</label>
                    <textarea className="field-textarea" placeholder="Describe your issue…" value={message} onChange={e => setMessage(e.target.value)} />
                </div>
                <button className="btn btn-pink btn-full" onClick={handleSubmit} disabled={submitting || !message.trim()}>
                    {submitting ? 'Submitting…' : 'Submit Complaint'}
                </button>
            </div>
        </>
    )
}

function ComplaintCard({ c, onResolve, loading }: { c: Complaint; onResolve: (id: number) => void; loading: boolean }) {
    const resolved = c.status === 'resolved'
    const meta = [
        c.identifier ? `ID: ${shortId(c.identifier)}` : null,
        c.room ? `Room ${c.room}` : null,
        c.created_at ? new Date(c.created_at * 1000).toLocaleDateString() : null,
    ].filter(Boolean).join(' · ')

    return (
        <div className={`complaint-card${resolved ? ' resolved' : ''}`}>
            <div className="complaint-top">
                <span className="complaint-title">
                    <MessageSquare size={12} style={{ display: 'inline', marginRight: 5, verticalAlign: 'middle' }} />
                    {c.category ?? 'General'}
                </span>
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
                        {loading ? '…' : 'Resolve'}
                    </button>
                )}
            </div>
        </div>
    )
}
