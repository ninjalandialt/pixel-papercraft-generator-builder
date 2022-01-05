module Thumbnail = {
  @react.component
  let make = (~thumbnail: Generator.thumnbnailDef) => {
    <div className="border bg-gray-100 p-4 w-72 h-72">
      <img src={thumbnail.url} width="256" height="256" />
    </div>
  }
}

module Video = {
  // https://web.dev/aspect-ratio/
  @react.component
  let make = (~video: Generator.videoDef) => {
    <div style={ReactDOM.Style.make(~maxWidth="640px", ())}>
      <div
        style={ReactDOM.Style.make(
          ~position="relative",
          ~width="100%",
          ~maxWidth="640px",
          ~paddingTop="56.25%",
          (),
        )}>
        <iframe
          style={ReactDOM.Style.make(
            ~position="absolute",
            ~top="0",
            ~width="100%",
            ~height="100%",
            (),
          )}
          src={video.url}
          allowFullScreen={true}
        />
      </div>
    </div>
  }
}

module Instructions = {
  @react.component
  let make = (~instructions: Generator.instructionsDef) => {
    <div className="mb-8"> {instructions} </div>
  }
}

module GeneratorPhotoOrVideo = {
  @react.component
  let make = (~generatorDef: Generator.generatorDef) => {
    <div>
      {switch generatorDef.video {
      | Some(video) => <Video video={video} />
      | None =>
        switch generatorDef.thumbnail {
        | Some(thumbnail) => <Thumbnail thumbnail={thumbnail} />
        | None => React.null
        }
      }}
    </div>
  }
}

module GeneratorInstructions = {
  @react.component
  let make = (~generatorDef: Generator.generatorDef) => {
    <div>
      {switch generatorDef.instructions {
      | Some(instructions) => <Instructions instructions={instructions} />
      | None => React.null
      }}
    </div>
  }
}

@react.component
let make = (
  ~generatorDef: Builder.generatorDef,
  ~afterInfo: option<React.element>=?,
  ~afterInputs: option<React.element>=?,
) => {
  let (model, setModel) = React.useState(_ => None)

  React.useEffect1(() => {
    ResourceLoader.loadResources(generatorDef)
    ->Promise.thenResolve(results => {
      switch results {
      | Error(exn) => Js.log(exn)
      | Ok(imageTuples, textureTuples) => {
          let model = Builder.Model.make()
          let model =
            imageTuples->Js.Array2.reduce(
              (acc, (id, image)) => Builder.addImage(acc, id, image),
              model,
            )
          let model =
            textureTuples->Js.Array2.reduce(
              (acc, (id, texture)) => Builder.addTexture(acc, id, texture),
              model,
            )
          ScriptRunner.run(generatorDef, model)
          ->Promise.thenResolve(model => {
            setModel(_ => Some(model))
          })
          ->ignore
        }
      }
    })
    ->ignore

    None
  }, [generatorDef])

  let runScript = model => {
    ScriptRunner.run(generatorDef, model)
    ->Promise.thenResolve(model => {
      setModel(_ => Some(model))
    })
    ->ignore
  }

  let onInputsChange = model => {
    runScript(model)
  }

  let onPagesInputsChange = () => {
    runScript(Generator.getModel())
  }

  <div>
    {switch model {
    | None => React.null
    | Some(model) =>
      <div>
        <div className="md:flex md:items-center mb-8">
          <div className="w-full mb-8 md:mb-0">
            <GeneratorPhotoOrVideo generatorDef={generatorDef} />
          </div>
          {switch afterInfo {
          | None => React.null
          | Some(afterInfo) => <div> afterInfo </div>
          }}
        </div>
        <GeneratorInstructions generatorDef />
        <GeneratorInputs model onChange={onInputsChange} />
        {switch afterInputs {
        | None => React.null
        | Some(afterInputs) => <div className="mb-8"> {afterInputs} </div>
        }}
        <GeneratorPages generatorDef model onChange={onPagesInputsChange} />
      </div>
    }}
  </div>
}

let default = make
