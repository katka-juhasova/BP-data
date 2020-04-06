describe('zip', function()
  it('behaves as an identity function if only one Observable argument is specified', function()
    expect(Rx.Observable.fromRange(1, 5):zip()).to.produce(1, 2, 3, 4, 5)
  end)

  it('groups values produced by the sources by their index', function()
    local observableA = Rx.Observable.fromRange(1, 3)
    local observableB = Rx.Observable.fromRange(2, 4)
    local observableC = Rx.Observable.fromRange(3, 5)
    expect(Rx.Observable.zip(observableA, observableB, observableC)).to.produce({{1, 2, 3}, {2, 3, 4}, {3, 4, 5}})
  end)

  it('tolerates nils', function()
    local observableA = Rx.Observable.create(function(observer)
      observer:onNext(nil)
      observer:onNext(nil)
      observer:onNext(nil)
      observer:onCompleted()
    end)
    local observableB = Rx.Observable.fromRange(3)
    local onNext = observableSpy(Rx.Observable.zip(observableA, observableB))
    expect(#onNext).to.equal(3)
  end)
end)
